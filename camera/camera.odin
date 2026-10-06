// camera — maps world metres (y-up) to window pixels (y-down) and back. Used by both input
// (mouse -> world) and render (world -> screen), so it lives on its own.
package camera

import "../physics"

SCREEN_WIDTH :: 1280
SCREEN_HEIGHT :: 720
SCALE :: f32(SCREEN_WIDTH) / physics.WORLD_WIDTH // pixels per metre

to_screen :: proc(p: physics.Vec2) -> [2]f32 {
	return {p.x * SCALE, f32(SCREEN_HEIGHT) - p.y * SCALE}
}

to_world :: proc(p: [2]f32) -> physics.Vec2 {
	return {p.x / SCALE, (f32(SCREEN_HEIGHT) - p.y) / SCALE}
}
