// Step 5 — body vs body collision.
//
// Soft bodies have no "solid shape" to test against each other, only rings of points. So the
// test is per point: is this point of body A inside the polygon of body B?
//
//   1. broad phase:  skip body pairs whose bounding boxes don't overlap
//   2. inside test:  cast a ray from the point; an odd number of edge crossings = inside
//   3. closest edge: the edge of B nearest to the point gives the way out: its outward normal,
//                    the depth, and where along the edge (t = 0..1) the point is
//   4. resolve:      push the point out and the edge back, split by inverse mass (and between
//                    the edge's two ends by t), then apply a bounce impulse along the normal and
//                    a friction impulse along the edge
//
// A body is static when its points have mass 0 (inverse mass 0): it never moves, everything
// else is pushed out of it.
//
// JellyPhysics: World::bodyCollide (steps 1–3), World::_handleCollisions (step 4). JellyPhysics
// treats the edge as moving with its ends' average velocity; here the velocity is interpolated
// at t, which matters for long edges.
package physics

Contact :: struct {
	point:          int, // the point that got inside another body (index into World.points)
	edge_a, edge_b: int, // the edge it's pushed out through
	edge_t:         f32, // 0 at edge_a, 1 at edge_b
	normal:         Vec2, // the edge's outward normal: the direction the point is pushed
	depth:          f32, // how far inside it was
}

AABB :: struct {
	min, max: Vec2,
}

inverse_mass :: proc(p: PointMass) -> f32 {
	return p.mass > 0 ? 1 / p.mass : 0
}

body_aabb :: proc(points: []PointMass) -> AABB {
	box := AABB{points[0].position, points[0].position}
	for p in points {
		box.min = {min(box.min.x, p.position.x), min(box.min.y, p.position.y)}
		box.max = {max(box.max.x, p.position.x), max(box.max.y, p.position.y)}
	}
	return box
}

aabb_overlap :: proc(a, b: AABB) -> bool {
	return a.min.x <= b.max.x && b.min.x <= a.max.x && a.min.y <= b.max.y && b.min.y <= a.max.y
}

// Ray cast to the right: every edge crossing flips inside/outside.
point_in_polygon :: proc(p: Vec2, ring: []PointMass) -> bool {
	inside := false
	for i in 0 ..< len(ring) {
		a, b := ring[i].position, ring[(i + 1) % len(ring)].position
		if (a.y > p.y) != (b.y > p.y) {
			cross_x := a.x + (p.y - a.y) / (b.y - a.y) * (b.x - a.x)
			if p.x < cross_x do inside = !inside
		}
	}
	return inside
}

// The edge of `ring` nearest to `p`. `first` is the ring's offset in World.points.
closest_edge :: proc(p: Vec2, ring: []PointMass, first: int) -> (contact: Contact, ok: bool) {
	contact.depth = max(f32)
	for i in 0 ..< len(ring) {
		j := (i + 1) % len(ring)
		a, b := ring[i].position, ring[j].position
		ab := b - a
		len2 := dot(ab, ab)
		if len2 < 1e-8 do continue
		t := clamp(dot(p - a, ab) / len2, 0, 1)
		dist := length(p - (a + ab * t))
		if dist < contact.depth {
			edge_normal := Vec2{ab.y, -ab.x} / length(ab) // outward for a counter-clockwise ring
			contact = {first + i, first + i, first + j, t, edge_normal, dist}
			ok = true
		}
	}
	return
}

// Steps 1–3 for every pair of bodies: every point of one that is inside the other.
find_contacts :: proc(w: ^World) {
	clear(&w.contacts)
	for &b in w.bodies do b.aabb = body_aabb(body_points(w, b))
	for a, ai in w.bodies {
		for b, bi in w.bodies {
			if ai == bi || !aabb_overlap(a.aabb, b.aabb) do continue
			if is_static(w, a) && is_static(w, b) do continue
			if a.group != 0 && a.group == b.group do continue // step 6: parts of one car
			ring := body_points(w, b)
			for i in a.first ..< a.first + a.count {
				p := w.points[i].position
				if p.x < b.aabb.min.x || p.x > b.aabb.max.x || p.y < b.aabb.min.y || p.y > b.aabb.max.y do continue
				if !point_in_polygon(p, ring) do continue
				if contact, ok := closest_edge(p, ring, b.first); ok {
					contact.point = i
					append(&w.contacts, contact)
				}
			}
		}
	}
}

// Step 4: separate, then bounce + friction.
resolve_contact :: proc(points: []PointMass, c: Contact, elasticity, friction: f32) {
	p, e1, e2 := &points[c.point], &points[c.edge_a], &points[c.edge_b]
	w1, w2 := 1 - c.edge_t, c.edge_t
	inv_p := inverse_mass(p^)
	edge_mass := e1.mass + e2.mass
	inv_e := edge_mass > 0 ? 1 / edge_mass : 0
	inv_sum := inv_p + inv_e
	if inv_sum == 0 do return

	// Position: lighter side moves more.
	p.position += c.normal * (c.depth * inv_p / inv_sum)
	edge_move := c.normal * (c.depth * inv_e / inv_sum)
	e1.position -= edge_move * w1
	e2.position -= edge_move * w2

	// Velocity: only if they're still moving into each other.
	relative := p.velocity - (e1.velocity * w1 + e2.velocity * w2)
	approach := dot(relative, c.normal)
	if approach >= 0 do return
	tangent := Vec2{-c.normal.y, c.normal.x}
	bounce := -(1 + elasticity) * approach / inv_sum // normal impulse
	rub := -dot(relative, tangent) * friction / inv_sum // removes a share of the sliding speed
	impulse := c.normal * bounce + tangent * rub
	p.velocity += impulse * inv_p
	e1.velocity -= impulse * (inv_e * w1)
	e2.velocity -= impulse * (inv_e * w2)
}

collide_bodies :: proc(w: ^World) {
	find_contacts(w)
	for c in w.contacts do resolve_contact(w.points[:], c, w.settings.elasticity, w.settings.contact_friction)
}

is_static :: proc(w: ^World, b: ShapeBody) -> bool {
	return w.points[b.first].mass == 0
}
