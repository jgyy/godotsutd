# Frog Shooter

A small top-down shooter made in Godot 4.7 from the supplied pixel-art assets.

## Play
Open the folder in Godot 4.7 and press F5, or run `godot --path .`

- Move: WASD / arrow keys (8 directions)
- Fire: Space or left mouse (needs a staff)
- Restart after game over: R

Pick up the wooden staff to start shooting. Crystal and mighty staffs appear
later and raise fire rate and damage. Grasshoppers are fast and fragile,
dragonflies are medium, ladybugs are slow and tough.

## Tests
`godot --headless -s tests/run_tests.gd`

## Layout
- `Assets/` supplied art
- `scenes/`, `scripts/` one pair per game object
- `tests/` headless suites, `tests/run_tests.gd` is the runner
- `docs/superpowers/` design spec and implementation plan
