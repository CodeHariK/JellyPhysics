// The world: every point, spring and body, plus the settings a scene picked.
// `step` runs one fixed timestep in the order the steps introduced each idea.
package physics

STEP :: f32(1.0 / 240.0) // fixed physics step; small steps keep stiff springs stable

Settings :: struct {
	spring_k, spring_damping: f32, // step 2
	shape_matching:           bool, // step 3
	shape_k, shape_damping:   f32,
	restitution, friction:    f32, // step 1 (world box)
}

World :: struct {
	points:   [dynamic]PointMass,
	springs:  [dynamic]Spring,
	bodies:   [dynamic]ShapeBody,
	drag:     Drag,
	settings: Settings,
}

add_point :: proc(w: ^World, position: Vec2, velocity := Vec2{}, mass := f32(1)) -> int {
	append(&w.points, PointMass{position = position, velocity = velocity, mass = mass})
	return len(w.points) - 1
}

clear_world :: proc(w: ^World) {
	clear(&w.points)
	clear(&w.springs)
	clear(&w.bodies)
	w.drag = {}
	w.settings = {}
}

destroy_world :: proc(w: ^World) {
	delete(w.points)
	delete(w.springs)
	delete(w.bodies)
}

step :: proc(w: ^World, dt: f32) {
	s := w.settings
	apply_gravity(w.points[:]) // step 1
	apply_springs(w.points[:], w.springs[:], s.spring_k, s.spring_damping) // step 2
	for &b in w.bodies { 	// step 3
		points := body_points(w, b)
		derive_frame(&b, points)
		if s.shape_matching do apply_shape_matching(&b, points, s.shape_k, s.shape_damping)
	}
	apply_drag(w.drag, w.points[:])
	integrate(w.points[:], dt) // step 1
	collide_bounds(w.points[:], s.restitution, s.friction)
}
