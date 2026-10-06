// physics — the simulation only. No raylib, no input, no drawing.
package physics

import "core:math/linalg"

Vec2 :: [2]f32

length :: proc(v: Vec2) -> f32 {
	return linalg.length(v)
}

dot :: proc(a, b: Vec2) -> f32 {
	return a.x * b.x + a.y * b.y
}
