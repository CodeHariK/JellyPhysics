# JellyPhysics in Odin — one step at a time

A from-scratch rebuild of the ideas in Walaber's JellyPhysics (the soft-body engine behind
JellyCar). One program; number keys switch between steps, and
each step adds exactly one idea.

## Layout

| Folder | Package does | Knows about raylib? |
|---|---|---|
| `physics/` | the simulation: points, springs, shape matching, world step | no |
| `scenes/` | one file per learning step: builds a world, picks settings, lists actions | no |
| `input/` | keyboard + mouse → plain `Commands` (changes nothing itself) | yes |
| `render/` | draws the world (reads it, never changes it) | yes |
| `ui/` | text overlay: title, status, controls, help | yes |
| `camera/` | world metres ↔ window pixels | no |
| `main.odin` | app loop: poll input → apply → step physics → draw | yes |

## Steps

| Key | Physics file | Scene | Idea | JellyPhysics source |
|---|---|---|---|---|
| 1 | `point_mass.odin`, `bounds.odin` | `step1.odin` | point masses, gravity, semi-implicit Euler, fixed timestep | `PointMass.cpp` |
| 2 | `spring.odin`, `drag.odin` | `step2.odin` | damped Hooke springs, edge vs internal (diagonal) springs | `VectorTools::calculateSpringForce`, `SpringBody.cpp` |
| 3 | `shape_matching.odin` | `step3.odin` | derive centre + angle, spring points to the rotated rest shape | `Body::derivePositionAndAngle`, `SpringBody::accumulateInternalForces` |

## Run

Needs Odin with `vendor:raylib`; opens the latest step:

```
odin run . -out:jelly
```

`-- --selftest N` runs step N for 3 seconds, saves `selftest.png`, prints a short report and
quits (used to check a step builds and behaves).
