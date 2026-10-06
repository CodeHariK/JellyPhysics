// render — draws the physics world with raylib. Reads the world, never changes it.
package render

import "../camera"
import "../physics"
import "../scenes"
import rl "vendor:raylib"

BACKGROUND :: rl.Color{235, 245, 255, 255}
GHOST :: rl.Color{150, 160, 180, 255}
STATIC :: rl.Color{110, 115, 125, 255}
POINT_RADIUS :: 7

draw_world :: proc(w: ^physics.World, overlays: scenes.Overlays) {
	rl.ClearBackground(BACKGROUND)
	line({0, 0}, {physics.WORLD_WIDTH, 0}, 3, rl.DARKGRAY) // floor
	for b in w.bodies do if physics.is_static(w, b) do fill_body(b, physics.body_points(w, b), STATIC)
	if .Ghost in overlays && w.settings.shape_matching {
		for b in w.bodies do draw_ghost(b, physics.body_points(w, b))
	}
	if .Pressure in overlays {
		for b in w.bodies do if b.gas > 0 do draw_pressure(b, physics.body_points(w, b))
	}
	for s in w.springs {
		color := .Strain in overlays ? strain_color(w.points[:], s) : rl.GRAY
		line(w.points[s.a].position, w.points[s.b].position, 3, color)
	}
	if w.drag.active do line(w.drag.target, w.points[w.drag.point].position, 1, rl.ORANGE)
	for p in w.points {
		if .Velocity in overlays do line(p.position, p.position + p.velocity * 0.15, 2, rl.ORANGE)
		rl.DrawCircleV(camera.to_screen(p.position), POINT_RADIUS, rl.MAROON)
	}
	if .Contacts in overlays {
		for c in w.contacts {
			p := w.points[c.point].position
			rl.DrawCircleV(camera.to_screen(p), POINT_RADIUS - 2, rl.RED)
			line(p, p + c.normal * 0.4, 2, rl.RED)
		}
	}
}

// Fan of triangles from the body's centre (fine for the convex-ish bodies used here).
fill_body :: proc(b: physics.ShapeBody, points: []physics.PointMass, color: rl.Color) {
	c := camera.to_screen(b.center)
	for i in 0 ..< b.count {
		a := camera.to_screen(points[i].position)
		n := camera.to_screen(points[(i + 1) % b.count].position)
		rl.DrawTriangle(c, a, n, color)
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

// The rest shape placed at the derived centre + angle, the pull toward it, and the frame.
draw_ghost :: proc(b: physics.ShapeBody, points: []physics.PointMass) {
	for i in 0 ..< b.count {
		line(b.target[i], b.target[(i + 1) % b.count], 1, GHOST)
		line(points[i].position, b.target[i], 1, rl.ORANGE)
	}
	rl.DrawCircleV(camera.to_screen(b.center), 4, rl.DARKBLUE)
	line(b.center, b.center + physics.rotate({0.6, 0}, b.angle), 2, rl.DARKBLUE)
}

// The gas: a tinted fill (fan from the centre) plus an arrow for the push on each point.
draw_pressure :: proc(b: physics.ShapeBody, points: []physics.PointMass) {
	GAS :: rl.Color{120, 170, 255, 70}
	PUSH_SCALE :: 0.01 // metres of arrow per newton
	fill_body(b, points, GAS)
	for p, i in points do line(p.position, p.position + b.push[i] * PUSH_SCALE, 2, rl.BLUE)
}
