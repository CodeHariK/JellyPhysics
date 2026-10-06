// Step 3 — shape matching. See physics/shape_matching.odin.
//
// A 12-point circle and a 10-point rectangle with edge springs only (no diagonals). Shape
// matching alone keeps them from collapsing; S turns it off, D squashes them to watch them
// recover.
package scenes

import "core:fmt"
import "core:math"
import "../physics"

STEP3_HELP := []string {
	"grey = rest shape placed at the body's centre + angle   orange = pull toward it",
	"blue dot + line = derived centre and angle",
}

STEP3_ACTIONS := []Action{{'S', "shape matching on/off", step3_toggle}, {'D', "squash", step3_squash}}

step3 :: proc() -> Scene {
	return Scene {
		title = "Step 3: shape matching",
		help = STEP3_HELP,
		overlays = {.Strain, .Ghost},
		actions = STEP3_ACTIONS,
		setup = step3_setup,
		status = step3_status,
		selftest_poke = step3_squash,
		report = step3_report,
	}
}

step3_setup :: proc(w: ^physics.World) {
	w.settings = {
		spring_k       = 300,
		spring_damping = 10,
		shape_matching = true,
		shape_k        = 150,
		shape_damping  = 8,
		restitution    = 0.3,
		friction       = 0.8,
	}
	circle: [12]physics.Vec2
	for &p, i in circle {
		a := f32(i) / 12 * math.TAU
		p = {math.cos(a), math.sin(a)} * 1.2
	}
	physics.add_body(w, circle[:], {4, 4})
	rectangle := [?]physics.Vec2{{0, 0}, {1, 0}, {2, 0}, {3, 0}, {3, 1}, {3, 2}, {2, 2}, {1, 2}, {0, 2}, {0, 1}}
	physics.add_body(w, rectangle[:], {9.5, 3})
}

step3_toggle :: proc(w: ^physics.World) {
	w.settings.shape_matching = !w.settings.shape_matching
}

// Squash every body to 30% of its height around its centre.
step3_squash :: proc(w: ^physics.World) {
	for b in w.bodies {
		points := physics.body_points(w, b)
		center: physics.Vec2
		for p in points do center += p.position
		center /= f32(len(points))
		for &p in points {
			p.position.y = center.y + (p.position.y - center.y) * 0.3
			p.velocity = {}
		}
	}
}

step3_status :: proc(w: ^physics.World) -> string {
	return fmt.tprintf("shape matching: %s", w.settings.shape_matching ? "ON" : "OFF")
}

body_height :: proc(w: ^physics.World, b: physics.ShapeBody) -> f32 {
	lo, hi := f32(math.F32_MAX), f32(-math.F32_MAX)
	for p in physics.body_points(w, b) {
		lo = min(lo, p.position.y)
		hi = max(hi, p.position.y)
	}
	return hi - lo
}

step3_report :: proc(w: ^physics.World) -> string {
	return fmt.tprintf(
		"step3: after squash, circle height %.2f (rest 2.40), rectangle height %.2f (rest 2.00)",
		body_height(w, w.bodies[0]),
		body_height(w, w.bodies[1]),
	)
}
