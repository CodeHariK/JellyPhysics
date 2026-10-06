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
	for p in w.points {
		if .Velocity in overlays do line(p.position, p.position + p.velocity * 0.15, 2, rl.ORANGE)
		rl.DrawCircleV(camera.to_screen(p.position), POINT_RADIUS, rl.MAROON)
	}
}

line :: proc(a, b: physics.Vec2, thickness: f32, color: rl.Color) {
	rl.DrawLineEx(camera.to_screen(a), camera.to_screen(b), thickness, color)
}

