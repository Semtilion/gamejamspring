# Rise of the Pharaoh

A tactical RPG built from scratch in **Godot 4 (GDScript)** featuring grid-based combat, custom pixel art, and dynamic audio systems.

## Technical Highlights

- **BFS pathfinding** with weighted terrain costs varying by unit class
- **Weapon triangle combat system** with hit/damage/crit formulas, doubling thresholds, and terrain modifiers
- **Dynamic music engine** — pause/resume with playback position preservation and synced crossfading during scene transitions
- **Animated battle screen** with per-unit idle spritesheets, evade sprites, slash effects, and bouncing damage/miss text
- **Procedural stage elements** — randomized enemy stats, terrain generation, and soul-based recruitment from defeated enemies
- **Full UI pipeline** — animated menus, combat forecasts, phase banners, fade-to-black transitions, and textured button systems

## How to Run

1. Clone the repository
2. Open in Godot 4
3. Run `main.tscn`
