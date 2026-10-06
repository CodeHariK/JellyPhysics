// Step 2 — springs. See physics/spring.odin.
//
// Left box: edge springs only — nothing resists shearing, so it folds flat.
// Right box: edge + diagonal ("internal") springs — it keeps its shape.
package scenes

import "core:fmt"
import "../physics"

STEP2_STIFFNESS := [?]f32{50, 300, 1500}

STEP2_HELP := []string {
	"left: edge springs only (shears flat)     right: + diagonal springs (holds shape)",
	"red = stretched   blue = squashed",
}

STEP2_ACTIONS := []Action{{'K', "stiffness", step2_cycle_stiffness}}

step2 :: proc() -> Scene {
	return Scene {
		title = "Step 2: springs (Hooke + damping)",
		help = STEP2_HELP,
		overlays = {.Strain},
		actions = STEP2_ACTIONS,
		setup = step2_setup,
		status = step2_status,
		report = step2_report,
	}
}

// A 2x2 m box with its bottom-left corner at `origin`. Points go counter-clockwise.
step2_add_box :: proc(w: ^physics.World, origin: physics.Vec2, diagonals: bool) {
	first := len(w.points)
	corners := [4]physics.Vec2{{0, 0}, {2, 0}, {2, 2}, {0, 2}}
	for c in corners do physics.add_point(w, origin + c)
	for i in 0 ..< 4 do physics.add_spring(w, first + i, first + (i + 1) % 4)
	if diagonals {
		physics.add_spring(w, first + 0, first + 2)
		physics.add_spring(w, first + 1, first + 3)
	}
}

step2_setup :: proc(w: ^physics.World) {
	w.settings = {spring_k = STEP2_STIFFNESS[1], spring_damping = 10, restitution = 0.3, friction = 0.8}
	step2_add_box(w, {3.5, 4}, diagonals = false)
	step2_add_box(w, {10.5, 4}, diagonals = true)
	// Lean the left box a little so its missing shear support shows straight away.
	w.points[2].position.x += 0.3
	w.points[3].position.x += 0.3
}

step2_cycle_stiffness :: proc(w: ^physics.World) {
	for k, i in STEP2_STIFFNESS {
		if k == w.settings.spring_k {
			w.settings.spring_k = STEP2_STIFFNESS[(i + 1) % len(STEP2_STIFFNESS)]
			return
		}
	}
	w.settings.spring_k = STEP2_STIFFNESS[0]
}

step2_status :: proc(w: ^physics.World) -> string {
	return fmt.tprintf("spring k = %.0f", w.settings.spring_k)
}

step2_report :: proc(w: ^physics.World) -> string {
	return fmt.tprintf("step2: left box top y = %.2f, right box top y = %.2f", w.points[2].position.y, w.points[6].position.y)
}
