// render — draws the physics world with raylib. Reads the world, never changes it.
package render

import "../camera"
import "../physics"
import "../scenes"
import rl "vendor:raylib"

BACKGROUND :: rl.Color{235, 245, 255, 255}
POINT_RADIUS :: 7

draw_world :: proc(w: ^physics.World, overlays: scenes.Overlays) {
	rl.ClearBackground(BACKGROUND)
	line({0, 0}, {physics.WORLD_WIDTH, 0}, 3, rl.DARKGRAY) // floor
	for s in w.springs {
		color := .Strain in overlays ? strain_color(w.points[:], s) : rl.GRAY
		line(w.points[s.a].position, w.points[s.b].position, 3, color)
	}
	if w.drag.active do line(w.drag.target, w.points[w.drag.point].position, 1, rl.ORANGE)
	for p in w.points {
		if .Velocity in overlays do line(p.position, p.position + p.velocity * 0.15, 2, rl.ORANGE)
		rl.DrawCircleV(camera.to_screen(p.position), POINT_RADIUS, rl.MAROON)
	}
}

line :: proc(a, b: physics.Vec2, thickness: f32, color: rl.Color) {
	rl.DrawLineEx(camera.to_screen(a), camera.to_screen(b), thickness, color)
}

// Blue = squashed, grey = at rest, red = stretched.
strain_color :: proc(points: []physics.PointMass, s: physics.Spring) -> rl.Color {
	dist := physics.length(points[s.a].position - points[s.b].position)
	strain := clamp((dist - s.rest) / s.rest * 4, -1, 1)
	if strain > 0 do return rl.ColorLerp(rl.GRAY, rl.RED, strain)
	return rl.ColorLerp(rl.GRAY, rl.BLUE, -strain)
}

