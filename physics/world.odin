// The world: every point, plus the settings a scene picked.
// `step` runs one fixed timestep in the order the steps introduced each idea.
package physics

STEP :: f32(1.0 / 240.0) // fixed physics step; small steps keep stiff springs stable

Settings :: struct {
	restitution, friction: f32, // step 1 (world box)
}

World :: struct {
	points:   [dynamic]PointMass,
	settings: Settings,
}

add_point :: proc(w: ^World, position: Vec2, velocity := Vec2{}, mass := f32(1)) -> int {
	append(&w.points, PointMass{position = position, velocity = velocity, mass = mass})
	return len(w.points) - 1
}

clear_world :: proc(w: ^World) {
	clear(&w.points)
	w.settings = {}
}

destroy_world :: proc(w: ^World) {
	delete(w.points)
}

step :: proc(w: ^World, dt: f32) {
	s := w.settings
	apply_gravity(w.points[:]) // step 1
	integrate(w.points[:], dt) // step 1
	collide_bounds(w.points[:], s.restitution, s.friction)
}
