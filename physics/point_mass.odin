// Step 1 — point masses.
//
// Everything in JellyPhysics is made of point masses: a position, a velocity, a force and a
// mass. No rotation, no shape. Forces are summed each step, then integrated with
// semi-implicit (symplectic) Euler:
//
//   velocity += force / mass * dt      (velocity first...)
//   position += velocity * dt          (...then position with the NEW velocity)
//
// Updating velocity first is what makes it "semi-implicit"; it is far more stable for springs
// than plain explicit Euler. JellyPhysics: PointMass::integrateForce.
package physics

GRAVITY :: Vec2{0, -9.8} // m/s², world is y-up

PointMass :: struct {
	position: Vec2,
	velocity: Vec2,
	force:    Vec2,
	mass:     f32,
}

// Every step starts the force sum with gravity (F = m g).
apply_gravity :: proc(points: []PointMass) {
	for &p in points do p.force = GRAVITY * p.mass
}

// Step 4: a tiny drag on every point, every step (velocity *= 1 - drag). Springs only damp
// motion along themselves, so some wobbles (a balloon breathing in and out) never die without
// it. JellyPhysics: Body::dampenVelocity (velocity *= 0.999 per step).
apply_air_drag :: proc(points: []PointMass, drag: f32) {
	for &p in points do p.velocity *= 1 - drag
}

integrate :: proc(points: []PointMass, dt: f32) {
	for &p in points {
		p.velocity += p.force / p.mass * dt
		p.position += p.velocity * dt
	}
}
