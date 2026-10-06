// Step 6 — joints and torque: what turns three soft bodies into a car.
//
// Joint: a spring (step 2) from one point of a body (the chassis) to the CENTRE of another body
// (a tyre). Rest length 0 makes it an axle pin; a soft spring makes it suspension. The tyre has
// no single centre point, so the opposite force is spread evenly over all its points.
//
// Torque: a soft body can't be rotated directly, so push every point along its tangent around
// the centre (perpendicular to centre → point). Positive torque spins counter-clockwise.
// Friction against the ground (step 5) turns that spin into forward motion.
//
// JellyCar: Car::update (chassis ↔ tyre springs via the tyre's derived position/velocity),
// Tire::accumulateExternalForces (tangential torque forces).
package physics

BodyJoint :: struct {
	point:      int, // chassis point (index into World.points)
	body:       int, // tyre (index into World.bodies)
	k, damping: f32,
}

body_velocity :: proc(points: []PointMass) -> Vec2 {
	v: Vec2
	for p in points do v += p.velocity
	return v / f32(len(points))
}

apply_joint :: proc(w: ^World, j: BodyJoint) {
	b := w.bodies[j.body]
	points := body_points(w, b)
	center := PointMass{position = b.center, velocity = body_velocity(points)}
	f := spring_force(w.points[j.point], center, 0, j.k, j.damping)
	w.points[j.point].force += f
	for &p in points do p.force -= f / f32(len(points))
}

// Like a motor: full push when still, fading to nothing at `max_spin` (surface speed, m/s).
// Without the limit a tyre in the air spins up forever and flings itself apart.
apply_torque :: proc(b: ShapeBody, points: []PointMass) {
	mean_velocity := body_velocity(points)
	spin: f32 // average surface speed, counter-clockwise positive
	for p in points {
		r := p.position - b.center
		dist := length(r)
		if dist > 0.0001 do spin += dot(p.velocity - mean_velocity, Vec2{-r.y, r.x} / dist)
	}
	spin /= f32(len(points))
	direction: f32 = b.torque > 0 ? 1 : -1
	strength := clamp(1 - spin * direction / b.max_spin, 0, 1)
	for &p in points {
		r := p.position - b.center
		dist := length(r)
		if dist < 0.0001 do continue
		p.force += Vec2{-r.y, r.x} / dist * (b.torque * strength) // counter-clockwise tangent
	}
}
