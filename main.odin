// JellyPhysics in Odin — the app loop. Wires the packages together and owns no logic of its own:
//
//   physics/  the simulation (no raylib)        scenes/  one file per learning step
//   input/    keyboard + mouse -> commands       render/  draws the world
//   ui/       text overlay                       camera/  world <-> screen mapping
//
//   odin run . -out:jelly                        opens the latest step
//   odin run . -out:jelly -- --selftest 2        runs step 2 for 3 s, saves selftest.png, prints a report
package main

import "camera"
import "core:fmt"
import "core:os"
import "core:strconv"
import "input"
import "physics"
import "render"
import "scenes"
import "ui"
import rl "vendor:raylib"

SELFTEST_FRAMES :: 180 // 3 s
SELFTEST_POKE_FRAME :: 30 // 0.5 s
GRAB_RADIUS :: 0.6 // metres

load :: proc(w: ^physics.World, index: int) -> scenes.Scene {
	scene := scenes.ALL[index]()
	physics.clear_world(w)
	scene.setup(w)
	return scene
}

// Click either adds a point or grabs the nearest one, depending on the scene.
apply_mouse :: proc(w: ^physics.World, scene: scenes.Scene, cmd: input.Commands) {
	w.drag.target = cmd.mouse
	if cmd.press {
		if scene.click_adds_point {
			physics.add_point(w, cmd.mouse)
		} else {
			grabbed := physics.nearest_point(w.points[:], cmd.mouse, GRAB_RADIUS)
			w.drag = {active = grabbed >= 0, point = grabbed, target = cmd.mouse}
		}
	}
	if cmd.release do w.drag.active = false
}

// `--selftest N`: returns whether to self-test and which scene (default: the latest).
parse_args :: proc() -> (self_test: bool, index: int) {
	index = len(scenes.ALL) - 1
	self_test = len(os.args) > 1 && os.args[1] == "--selftest"
	if self_test && len(os.args) > 2 {
		n, ok := strconv.parse_int(os.args[2])
		if ok && n >= 1 && n <= len(scenes.ALL) do index = n - 1
	}
	return
}

main :: proc() {
	self_test, index := parse_args()

	rl.SetConfigFlags({.MSAA_4X_HINT, .VSYNC_HINT})
	rl.InitWindow(camera.SCREEN_WIDTH, camera.SCREEN_HEIGHT, "JellyPhysics in Odin")
	defer rl.CloseWindow()
	rl.SetTargetFPS(60)

	world: physics.World
	defer physics.destroy_world(&world)
	scene := load(&world, index)
	paused := false
	accumulator: f32

	for frame := 0; !rl.WindowShouldClose(); frame += 1 {
		cmd := input.poll(scene, len(scenes.ALL))
		if cmd.select_scene >= 0 do index = cmd.select_scene
		if cmd.select_scene >= 0 || cmd.reset do scene = load(&world, index)
		if cmd.toggle_pause do paused = !paused
		if cmd.action >= 0 do scene.actions[cmd.action].run(&world)
		apply_mouse(&world, scene, cmd)
		if self_test && frame == SELFTEST_POKE_FRAME && scene.selftest_poke != nil do scene.selftest_poke(&world)

		// Fixed timestep: step the physics in STEP-sized slices, however long the frame was.
		if !paused {
			accumulator += min(rl.GetFrameTime(), 0.1)
			for accumulator >= physics.STEP {
				physics.step(&world, physics.STEP)
				accumulator -= physics.STEP
			}
		}

		rl.BeginDrawing()
		render.draw_world(&world, scene.overlays)
		ui.draw_hud(scene, &world, len(scenes.ALL), paused)
		rl.EndDrawing()
		free_all(context.temp_allocator)

		if self_test && frame == SELFTEST_FRAMES {
			rl.TakeScreenshot("selftest.png")
			fmt.println(scene.report(&world))
			break
		}
	}
}
