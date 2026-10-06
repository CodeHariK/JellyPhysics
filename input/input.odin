// input — reads keyboard and mouse into plain commands. Changes nothing itself; main applies
// the commands to the world.
package input

import "../camera"
import "../physics"
import "../scenes"
import rl "vendor:raylib"

Commands :: struct {
	mouse:        physics.Vec2, // cursor in world metres
	select_scene: int, // number key pressed: scene index, else -1
	reset:        bool,
	toggle_pause: bool,
	press:        bool, // left mouse went down this frame
	release:      bool, // left mouse went up this frame
	action:       int, // index into scene.actions, else -1
}

poll :: proc(scene: scenes.Scene, scene_count: int) -> Commands {
	c := Commands {
		mouse        = camera.to_world(rl.GetMousePosition()),
		select_scene = -1,
		reset        = rl.IsKeyPressed(.R),
		toggle_pause = rl.IsKeyPressed(.SPACE),
		press        = rl.IsMouseButtonPressed(.LEFT),
		release      = rl.IsMouseButtonReleased(.LEFT),
		action       = -1,
	}
	for i in 0 ..< scene_count {
		if rl.IsKeyPressed(rl.KeyboardKey(int(rl.KeyboardKey.ONE) + i)) do c.select_scene = i
	}
	for a, i in scene.actions {
		if rl.IsKeyPressed(rl.KeyboardKey(int(a.key))) do c.action = i // raylib letter keys = ASCII
	}
	return c
}
