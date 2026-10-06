// Step 1 — the world box: a floor and two walls.
//
// A point that ends up outside is pushed back to the boundary; its velocity into the wall is
// reflected and scaled by `restitution` (bounciness), and on the floor its sideways velocity is
// scaled by `friction`. Step 5 replaces this with real body-vs-body collision.
package physics

WORLD_WIDTH :: f32(16) // metres
WORLD_HEIGHT :: f32(9)

collide_bounds :: proc(points: []PointMass, restitution, friction: f32) {
	for &p in points {
		if p.position.y < 0 {
			p.position.y = 0
			p.velocity.y = -p.velocity.y * restitution
			p.velocity.x *= friction
		}
		if p.position.x < 0 {
			p.position.x = 0
			p.velocity.x = -p.velocity.x * restitution
		}
		if p.position.x > WORLD_WIDTH {
			p.position.x = WORLD_WIDTH
			p.velocity.x = -p.velocity.x * restitution
		}
	}
}
