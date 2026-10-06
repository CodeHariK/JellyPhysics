// The world: every point and spring, plus the settings a scene picked.
// `step` runs one fixed timestep in the order the steps introduced each idea.
package physics

STEP :: f32(1.0 / 240.0) // fixed physics step; small steps keep stiff springs stable

Settings :: struct {
	spring_k, spring_damping: f32, // step 2
	restitution, friction:    f32, // step 1 (world box)
}

World :: struct {
	points:   [dynamic]PointMass,
	springs:  [dynamic]Spring,
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
	w.drag = {}
	w.settings = {}
}

destroy_world :: proc(w: ^World) {
	delete(w.points)
	delete(w.springs)
}

step :: proc(w: ^World, dt: f32) {
	s := w.settings
	apply_gravity(w.points[:]) // step 1
	apply_springs(w.points[:], w.springs[:], s.spring_k, s.spring_damping) // step 2
	apply_drag(w.drag, w.points[:])
	integrate(w.points[:], dt) // step 1
	collide_bounds(w.points[:], s.restitution, s.friction)
}
