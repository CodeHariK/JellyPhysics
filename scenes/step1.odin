// Step 1 — point masses under gravity bouncing in the world box. See physics/point_mass.odin.
package scenes

import "core:fmt"
import "../physics"

STEP1_HELP := []string{"orange line = velocity"}

step1 :: proc() -> Scene {
	return Scene {
		title = "Step 1: point masses + semi-implicit Euler",
		help = STEP1_HELP,
		overlays = {.Velocity},
		click_adds_point = true,
		setup = step1_setup,
		status = step1_status,
		report = step1_report,
	}
}

step1_setup :: proc(w: ^physics.World) {
	w.settings = {restitution = 0.6, friction = 0.9}
	for i in 0 ..< 8 {
		physics.add_point(w, {2 + f32(i) * 1.6, 5 + f32(i % 3)}, velocity = {f32(i - 4) * 0.5, 0})
	}
}

step1_status :: proc(w: ^physics.World) -> string {
	return fmt.tprintf("%d particles", len(w.points))
}

step1_report :: proc(w: ^physics.World) -> string {
	p := w.points[0]
	return fmt.tprintf("step1: first particle at %v velocity %v", p.position, p.velocity)
}
