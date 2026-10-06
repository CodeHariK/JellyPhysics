// Dragging a point is just another spring (step 2): from a still target to the grabbed point.
// The physics doesn't know where the target comes from — the app feeds it the mouse.
package physics

DRAG_K :: 400
DRAG_DAMP :: 20

Drag :: struct {
	active: bool,
	point:  int, // index into World.points
	target: Vec2,
}

apply_drag :: proc(drag: Drag, points: []PointMass) {
	if !drag.active || drag.point >= len(points) do return
	p := &points[drag.point]
	p.force += spring_force(p^, PointMass{position = drag.target}, 0, DRAG_K, DRAG_DAMP)
}

// Index of the closest point within `max_dist`, or -1.
nearest_point :: proc(points: []PointMass, at: Vec2, max_dist: f32) -> int {
	best, best_dist := -1, max_dist
	for p, i in points {
		d := length(p.position - at)
		if d < best_dist do best, best_dist = i, d
	}
	return best
}
