// Step 4 — pressure.
//
// A ring of points with edge springs is a bag; fill it with gas and it becomes a balloon or a
// tyre. Ideal gas: pressure = gas / area (squash the bag → less area → more pressure). Pressure
// pushes every edge outward along its normal with force = pressure × edge length, half to each
// end point:
//
//   area   = |shoelace area of the ring|          (clamped so it never hits 0)
//   n_e    = outward normal of edge e             (counter-clockwise ring: (e.y, -e.x))
//   F_e    = n_e * gas * |e| / area
//
// No shape memory needed: the gas alone keeps the body round, and it squashes softly when it
// hits something — which is exactly the JellyCar tyre feel.
//
// JellyPhysics: PressureBody::accumulateInternalForces. It applies the full edge force to both
// end points along the averaged vertex normals; splitting each edge's force between its two ends
// (as here) is the same idea, just half the strength for the same gas amount.
package physics

import "core:math"

MIN_AREA :: f32(0.5)

// Shoelace formula: positive for a counter-clockwise ring.
polygon_area :: proc(points: []PointMass) -> f32 {
	sum: f32
	for p, i in points do sum += cross(p.position, points[(i + 1) % len(points)].position)
	return sum * 0.5
}

apply_pressure :: proc(b: ^ShapeBody, points: []PointMass) {
	b.area = max(math.abs(polygon_area(points)), MIN_AREA)
	for &push in b.push[:b.count] do push = {}
	for i in 0 ..< b.count {
		j := (i + 1) % b.count
		edge := points[j].position - points[i].position
		edge_length := length(edge)
		if edge_length < 0.0001 do continue
		normal := Vec2{edge.y, -edge.x} / edge_length
		force := normal * (b.gas * edge_length / b.area)
		b.push[i] += force * 0.5
		b.push[j] += force * 0.5
	}
	for &p, i in points do p.force += b.push[i]
}
