// Step 3 — shape matching.
//
// Springs alone only know lengths, so a body can end up twisted or inside-out and stay there.
// Shape matching gives the body a memory of its rest shape. Every step:
//
//   1. centre = average of the points
//   2. angle  = best-fit rotation of the rest shape onto the current points
//               atan2(Σ cross(rest_i, cur_i), Σ dot(rest_i, cur_i))
//   3. target_i = centre + rotate(rest_i, angle)
//   4. pull every point toward its target with a spring of rest length 0
//
// The body can still squash and wobble (that's the jelly), but it always wants to return to
// its rest shape, at whatever position and rotation it's currently at.
//
// JellyPhysics: Body::derivePositionAndAngle + SpringBody::accumulateInternalForces
// (mGlobalShape). JellyPhysics averages per-point angles with a wrap-around fix; the
// atan2-of-sums used here is the least-squares rotation and needs no wrap fix.
// JellyPhysics also gives the target the point's own velocity, which cancels the damping
// term; here the target moves with the body's mean velocity so the wobble settles.
package physics

import "core:math"

MAX_BODY_POINTS :: 16

ShapeBody :: struct {
	first, count: int, // this body's slice of World.points
	rest:         [MAX_BODY_POINTS]Vec2, // rest shape, centred on the origin
	center:       Vec2, // derived every step
	angle:        f32,
	target:       [MAX_BODY_POINTS]Vec2, // rest shape placed at center + angle
	gas:          f32, // step 4: 0 = no pressure (see pressure.odin)
	area:         f32, // step 4: derived every step
	push:         [MAX_BODY_POINTS]Vec2, // step 4: pressure force on each point
	aabb:         AABB, // step 5: bounding box, updated every step
	group:        int, // step 6: bodies sharing a non-zero group don't collide (one car's parts)
	torque:       f32, // step 6: spin force on each point (see joint.odin)
	max_spin:     f32, // step 6: surface speed (m/s) where the torque fades to 0
}

// Adds a closed ring of points (counter-clockwise, local coords) joined by edge springs.
// mass = 0 makes a static body (step 5). Returns the body's index in World.bodies.
add_body :: proc(w: ^World, shape: []Vec2, origin: Vec2, gas := f32(0), mass := f32(1)) -> int {
	assert(len(shape) <= MAX_BODY_POINTS)
	body := ShapeBody{first = len(w.points), count = len(shape), gas = gas}
	centroid: Vec2
	for p in shape do centroid += p
	centroid /= f32(len(shape))
	for p, i in shape {
		body.rest[i] = p - centroid
		add_point(w, origin + p, mass = mass)
	}
	for i in 0 ..< body.count do add_spring(w, body.first + i, body.first + (i + 1) % body.count)
	append(&w.bodies, body)
	return len(w.bodies) - 1
}

body_points :: proc(w: ^World, b: ShapeBody) -> []PointMass {
	return w.points[b.first:][:b.count]
}

// 1 + 2 + 3: where is the body, how is it rotated, and where should each point be?
derive_frame :: proc(b: ^ShapeBody, points: []PointMass) {
	center: Vec2
	for p in points do center += p.position
	center /= f32(len(points))
	sin_sum, cos_sum: f32
	for p, i in points {
		sin_sum += cross(b.rest[i], p.position - center)
		cos_sum += dot(b.rest[i], p.position - center)
	}
	b.center = center
	b.angle = math.atan2(sin_sum, cos_sum)
	for i in 0 ..< b.count do b.target[i] = center + rotate(b.rest[i], b.angle)
}

// 4: spring each point to its target slot.
apply_shape_matching :: proc(b: ^ShapeBody, points: []PointMass, k, damping: f32) {
	mean_velocity: Vec2
	for p in points do mean_velocity += p.velocity
	mean_velocity /= f32(len(points))
	for &p, i in points {
		slot := PointMass{position = b.target[i], velocity = mean_velocity}
		p.force += spring_force(p, slot, 0, k, damping)
	}
}
