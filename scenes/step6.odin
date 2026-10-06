// Step 6 — a jelly car. See physics/joint.odin.
//
// Everything so far, put together:
//   chassis = shape-matched soft body (step 3), its two lowest points are the axles
//   tyres   = gas-filled + shape-matched rings (steps 3 + 4)
//   joints  = a spring from each axle point to its tyre's centre (suspension)
//   drive   = torque on both tyres; ground friction (step 5) turns spin into motion
//   group   = the car's three bodies share a collision group so they don't push each other apart
// The course is static bodies (step 5): a hump and a ramp up to a ledge.
package scenes

import "core:fmt"
import "core:math"
import "../physics"

CAR_GROUP :: 1
DRIVE_TORQUE :: 30 // newtons of spin force per tyre point at full throttle
TYRE_MAX_SPIN :: 8 // m/s of tyre surface speed where the motor stops pushing
SUSPENSION_K :: 900
SUSPENSION_DAMPING :: 30
TYRE_GAS :: 40 // pressure = gas / area, and a small tyre has a small area: keep the gas low

// Chassis outline, counter-clockwise from the rear axle. Points 0 and 1 are the axles.
CHASSIS := [?]physics.Vec2{{0.6, 0}, {2.4, 0}, {3.0, 0.35}, {2.5, 0.75}, {1.7, 1.25}, {0.5, 1.2}, {0, 0.5}}
CHASSIS_START :: physics.Vec2{0.6, 1.1}

STEP6_HELP := []string {
	"chassis = shape matching   tyres = pressure + shape matching   orange = suspension joints",
	"tyres spin by pushing every point along its tangent; friction with the ground drives the car",
}

step6 :: proc() -> Scene {
	return Scene {
		title = "Step 6: jelly car",
		help = STEP6_HELP,
		overlays = {.Pressure, .Joints},
		setup = step6_setup,
		status = step6_status,
		drive = step6_drive,
		report = step6_report,
	}
}

step6_setup :: proc(w: ^physics.World) {
	w.settings = {
		spring_k         = 1500,
		spring_damping   = 15,
		shape_matching   = true,
		shape_k          = 400,
		shape_damping    = 15,
		air_drag         = 0.001,
		collisions       = true,
		elasticity       = 0.1,
		contact_friction = 0.8,
		restitution      = 0.2,
		friction         = 0.8,
	}
	hump := [?]physics.Vec2{{4.5, 0}, {9.5, 0}, {8.3, 0.35}, {7, 0.5}, {5.7, 0.35}}
	physics.add_body(w, hump[:], {0, 0}, mass = 0)
	ledge := [?]physics.Vec2{{11, 0}, {16, 0}, {16, 1.3}, {14, 1.3}}
	physics.add_body(w, ledge[:], {0, 0}, mass = 0)

	chassis := physics.add_body(w, CHASSIS[:], CHASSIS_START)
	for axle in 0 ..< 2 {
		tyre := step6_add_tyre(w, CHASSIS_START + CHASSIS[axle])
		append(&w.joints, physics.BodyJoint{w.bodies[chassis].first + axle, tyre, SUSPENSION_K, SUSPENSION_DAMPING})
	}
	w.bodies[chassis].group = CAR_GROUP
}

step6_add_tyre :: proc(w: ^physics.World, center: physics.Vec2) -> int {
	ring: [12]physics.Vec2
	for &p, i in ring {
		a := f32(i) / f32(len(ring)) * math.TAU // counter-clockwise
		p = {math.cos(a), math.sin(a)} * 0.45
	}
	tyre := physics.add_body(w, ring[:], center, gas = TYRE_GAS)
	w.bodies[tyre].group = CAR_GROUP
	w.bodies[tyre].max_spin = TYRE_MAX_SPIN
	return tyre
}

// Right = clockwise spin = forward, so the torque is the negative throttle.
step6_drive :: proc(w: ^physics.World, throttle: f32) {
	for j in w.joints do w.bodies[j.body].torque = -throttle * DRIVE_TORQUE
}

step6_chassis :: proc(w: ^physics.World) -> physics.ShapeBody {
	return w.bodies[2] // after the two static bodies
}

step6_status :: proc(w: ^physics.World) -> string {
	c := step6_chassis(w)
	speed := physics.body_velocity(physics.body_points(w, c)).x
	return fmt.tprintf("speed %.1f m/s   chassis tilt %.0f deg", speed, math.to_degrees(c.angle))
}

step6_report :: proc(w: ^physics.World) -> string {
	c := step6_chassis(w)
	front, rear := w.bodies[4], w.bodies[3]
	start: physics.Vec2
	for p in CHASSIS do start += p
	start = CHASSIS_START + start / f32(len(CHASSIS))
	return fmt.tprintf(
		"step6: chassis moved %.2f m right (start x %.2f), now at y %.2f, tilt %.0f deg; tyre areas %.2f / %.2f (rest %.2f)",
		c.center.x - start.x,
		start.x,
		c.center.y,
		math.to_degrees(c.angle),
		rear.area,
		front.area,
		math.PI * 0.45 * 0.45,
	)
}
