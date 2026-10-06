// Step 2 — springs.
//
// A soft body is point masses joined by springs. Each spring wants to stay at its rest length:
// stretch it and it pulls the ends together, squash it and it pushes them apart. A damper
// slows the ends' relative motion along the spring so it doesn't wobble forever.
//
//   dir = normalize(a - b)
//   x   = rest - |a - b|                    (+ squashed, - stretched)
//   v   = dot(a.vel - b.vel, dir)            (how fast the ends separate)
//   F_a = dir * (k * x - damping * v)        (Hooke's law + damping)
//   F_b = -F_a                               (Newton's 3rd law)
//
// JellyPhysics: VectorTools::calculateSpringForce, SpringBody::accumulateInternalForces.
package physics

Spring :: struct {
	a, b: int, // indices into World.points
	rest: f32, // rest length, taken from the starting shape
}

// Returns the force on `a`; the force on `b` is its negative.
spring_force :: proc(a, b: PointMass, rest, k, damping: f32) -> Vec2 {
	delta := a.position - b.position
	dist := length(delta)
	if dist < 0.0001 do return {}
	dir := delta / dist
	stretch := rest - dist
	closing_speed := dot(a.velocity - b.velocity, dir)
	return dir * (k * stretch - damping * closing_speed)
}

// Spring between two existing points, resting at their current distance.
add_spring :: proc(w: ^World, a, b: int) {
	rest := length(w.points[a].position - w.points[b].position)
	append(&w.springs, Spring{a = a, b = b, rest = rest})
}

apply_springs :: proc(points: []PointMass, springs: []Spring, k, damping: f32) {
	for s in springs {
		f := spring_force(points[s.a], points[s.b], s.rest, k, damping)
		points[s.a].force += f
		points[s.b].force -= f
	}
}
