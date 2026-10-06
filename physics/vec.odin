// physics — the simulation only. No raylib, no input, no drawing.
package physics

import "core:math"
import "core:math/linalg"

Vec2 :: [2]f32

length :: proc(v: Vec2) -> f32 {
	return linalg.length(v)
}

dot :: proc(a, b: Vec2) -> f32 {
	return a.x * b.x + a.y * b.y
}

// 2D cross product (z of the 3D cross): > 0 when b is counter-clockwise from a.
cross :: proc(a, b: Vec2) -> f32 {
	return a.x * b.y - a.y * b.x
}

rotate :: proc(v: Vec2, angle: f32) -> Vec2 {
	s, c := math.sin(angle), math.cos(angle)
	return {c * v.x - s * v.y, s * v.x + c * v.y}
}
