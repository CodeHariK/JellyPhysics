// scenes — one file per learning step. A scene builds a physics.World, picks its settings and
// lists its actions. It says WHAT to show (overlays, help text), never HOW: no raylib here.
package scenes

import "../physics"

Overlay :: enum {
	Velocity, // a line along each point's velocity
	Strain, // springs coloured by stretch / squash
	Ghost, // shape-matching targets
	Pressure, // pressure push on each point
	Contacts, // points inside another body + their push-out normal
}

Overlays :: bit_set[Overlay]

// A scene-specific command, triggered by a key (an uppercase letter).
Action :: struct {
	key:   rune,
	label: string,
	run:   proc(w: ^physics.World),
}

Scene :: struct {
	title:            string,
	help:             []string,
	overlays:         Overlays,
	click_adds_point: bool, // false: clicking grabs and drags a point
	actions:          []Action,
	setup:            proc(w: ^physics.World),
	status:           proc(w: ^physics.World) -> string, // optional live status line
	selftest_poke:    proc(w: ^physics.World), // optional: disturbance applied in --selftest
	report:           proc(w: ^physics.World) -> string, // --selftest summary
}

ALL := [?]proc() -> Scene{step1, step2, step3, step4, step5}
