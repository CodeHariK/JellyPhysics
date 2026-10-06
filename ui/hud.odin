// ui — the text overlay: title, status, controls and help. Drawn on top of the world.
package ui

import "../camera"
import "../physics"
import "../scenes"
import "core:fmt"
import "core:strings"
import rl "vendor:raylib"

TITLE_SIZE :: 24
TEXT_SIZE :: 18
LINE_HEIGHT :: 24
MARGIN :: 16

draw_hud :: proc(scene: scenes.Scene, w: ^physics.World, scene_count: int, paused: bool) {
	rl.DrawText(cstr(scene.title), MARGIN, 12, TITLE_SIZE, rl.DARKGRAY)

	global := fmt.ctprintf("1-%d: step   R: reset   Space: %s", scene_count, paused ? "resume" : "pause")
	rl.DrawText(global, camera.SCREEN_WIDTH - rl.MeasureText(global, TEXT_SIZE) - MARGIN, 16, TEXT_SIZE, rl.GRAY)

	y := i32(44)
	text_line(controls_line(scene, w), &y, rl.DARKGRAY)
	for line in scene.help do text_line(line, &y, rl.GRAY)
}

// "status   click: …   K: …   S: …"
controls_line :: proc(scene: scenes.Scene, w: ^physics.World) -> string {
	b := strings.builder_make(context.temp_allocator)
	if scene.status != nil do fmt.sbprintf(&b, "%s   ", scene.status(w))
	fmt.sbprint(&b, scene.click_adds_point ? "click: add point" : "drag points")
	for a in scene.actions do fmt.sbprintf(&b, "   %r: %s", a.key, a.label)
	return strings.to_string(b)
}

text_line :: proc(text: string, y: ^i32, color: rl.Color) {
	rl.DrawText(cstr(text), MARGIN, y^, TEXT_SIZE, color)
	y^ += LINE_HEIGHT
}

cstr :: proc(s: string) -> cstring {
	return strings.clone_to_cstring(s, context.temp_allocator)
}
