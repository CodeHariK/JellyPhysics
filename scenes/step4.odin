// Step 4 — pressure. See physics/pressure.odin.
//
// Three identical 16-point rings with edge springs only and no shape matching. The only
// difference is the gas inside: none (collapses into a puddle), a little (a soft blob) and a lot
// (a firm ball). G adds gas, L lets some out, D squashes them.
package scenes

import "core:fmt"
import "core:math"
import "../physics"

STEP4_GAS := [3]f32{0, 120, 320}

STEP4_HELP := []string {
	"left: no gas (collapses)   middle: little gas (soft)   right: lots of gas (firm)",
	"blue arrows = pressure push = gas x edge length / area, along each edge's outward normal",
}

STEP4_ACTIONS := []Action{{'G', "more gas", step4_more_gas}, {'L', "let gas out", step4_less_gas}, {'D', "squash", step3_squash}}

step4 :: proc() -> Scene {
	return Scene {
		title = "Step 4: pressure (gas-filled bodies)",
		help = STEP4_HELP,
		overlays = {.Strain, .Pressure},
		actions = STEP4_ACTIONS,
		setup = step4_setup,
		status = step4_status,
		selftest_poke = step3_squash,
		report = step4_report,
	}
}

step4_setup :: proc(w: ^physics.World) {
	w.settings = {spring_k = 2000, spring_damping = 10, air_drag = 0.002, restitution = 0.3, friction = 0.8}
	ring: [16]physics.Vec2
	for &p, i in ring {
		a := f32(i) / f32(len(ring)) * math.TAU // counter-clockwise
		p = {math.cos(a), math.sin(a)} * 1.1
	}
	for gas, i in STEP4_GAS do physics.add_body(w, ring[:], {3 + f32(i) * 5, 4}, gas)
}

step4_more_gas :: proc(w: ^physics.World) {
	for &b in w.bodies do b.gas *= 1.25
}

step4_less_gas :: proc(w: ^physics.World) {
	for &b in w.bodies do b.gas *= 0.8
}

step4_status :: proc(w: ^physics.World) -> string {
	return fmt.tprintf("gas: %.0f / %.0f / %.0f", w.bodies[0].gas, w.bodies[1].gas, w.bodies[2].gas)
}

step4_report :: proc(w: ^physics.World) -> string {
	return fmt.tprintf(
		"step4: after squash, heights (rest 2.20): no gas %.2f, soft %.2f, firm %.2f; firm area %.2f (rest %.2f)",
		body_height(w, w.bodies[0]),
		body_height(w, w.bodies[1]),
		body_height(w, w.bodies[2]),
		w.bodies[2].area,
		math.PI * 1.1 * 1.1,
	)
}
