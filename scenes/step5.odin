// Step 5 — body vs body collision. See physics/collision.odin.
//
// A static ramp and a static step (mass 0), two gas-filled balls and two shape-matched jelly
// boxes. They fall, land, roll and stack: every point that ends up inside another body is
// pushed back out through that body's nearest edge. B drops another ball, X another box.
package scenes

import "core:fmt"
import "core:math"
import "../physics"

STEP5_HELP := []string {
	"grey = static bodies (mass 0)   red = contacts: a point inside another body + its push-out normal",
	"balls = pressure + shape matching (like a JellyCar tyre)   boxes = shape matching only",
}

STEP5_ACTIONS := []Action{{'B', "drop ball", step5_drop_ball}, {'X', "drop box", step5_drop_box}}

STEP5_BOX := [?]physics.Vec2{{0, 0}, {0.8, 0}, {1.6, 0}, {1.6, 0.6}, {1.6, 1.2}, {0.8, 1.2}, {0, 1.2}, {0, 0.6}}

step5 :: proc() -> Scene {
	return Scene {
		title = "Step 5: body vs body collision",
		help = STEP5_HELP,
		overlays = {.Strain, .Pressure, .Contacts},
		actions = STEP5_ACTIONS,
		setup = step5_setup,
		status = step5_status,
		report = step5_report,
	}
}

step5_setup :: proc(w: ^physics.World) {
	w.settings = {
		spring_k         = 1000,
		spring_damping   = 10,
		shape_matching   = true,
		shape_k          = 300,
		shape_damping    = 10,
		air_drag         = 0.001,
		collisions       = true,
		elasticity       = 0.2,
		contact_friction = 0.3,
		restitution      = 0.3,
		friction         = 0.8,
	}
	ramp := [?]physics.Vec2{{0, 0}, {7, 0}, {0, 3.5}}
	physics.add_body(w, ramp[:], {0, 0}, mass = 0)
	step := [?]physics.Vec2{{0, 0}, {5, 0}, {5, 1.5}, {0, 1.5}}
	physics.add_body(w, step[:], {11, 0}, mass = 0)

	step5_add_ball(w, {1.5, 6.5})
	step5_add_ball(w, {5, 7.5})
	physics.add_body(w, STEP5_BOX[:], {8, 5})
	physics.add_body(w, STEP5_BOX[:], {12.5, 6.5})
}

step5_add_ball :: proc(w: ^physics.World, center: physics.Vec2) {
	ring: [12]physics.Vec2
	for &p, i in ring {
		a := f32(i) / f32(len(ring)) * math.TAU // counter-clockwise
		p = {math.cos(a), math.sin(a)} * 0.8
	}
	physics.add_body(w, ring[:], center, gas = 150)
}

// New bodies drop in at a different x each time.
step5_drop_x :: proc(w: ^physics.World) -> f32 {
	return 1.5 + math.mod(f32(len(w.bodies)) * 2.7, 12)
}

step5_drop_ball :: proc(w: ^physics.World) {
	step5_add_ball(w, {step5_drop_x(w), 8})
}

step5_drop_box :: proc(w: ^physics.World) {
	physics.add_body(w, STEP5_BOX[:], {step5_drop_x(w), 7.5})
}

step5_status :: proc(w: ^physics.World) -> string {
	return fmt.tprintf("%d bodies   %d contacts", len(w.bodies), len(w.contacts))
}

step5_report :: proc(w: ^physics.World) -> string {
	deepest: f32
	for c in w.contacts do deepest = max(deepest, c.depth)
	return fmt.tprintf(
		"step5: centres ball %.2f,%.2f  ball %.2f,%.2f  box %.2f,%.2f  box %.2f,%.2f   contacts %d, deepest %.3f",
		w.bodies[2].center.x, w.bodies[2].center.y,
		w.bodies[3].center.x, w.bodies[3].center.y,
		w.bodies[4].center.x, w.bodies[4].center.y,
		w.bodies[5].center.x, w.bodies[5].center.y,
		len(w.contacts),
		deepest,
	)
}
