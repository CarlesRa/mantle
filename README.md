# 🎮 Godot 4 - Game Jam Base Project

A starter template for Game Jams built with **Godot 4**! 🚀

Designed to jumpstart development during the first hours of a jam, providing an optimized Web-first setup and quick development practices.

---

## 🛠️ Technical Specifications

* **Engine:** Godot 4.x (Compatibility Renderer / WebGL 2.0)
* **Language:** GDScript
* **Target Platforms:** Web (itch.io / Newgrounds) & Desktop (Linux, Windows, macOS)
* **Version Control:** Git

---

## 🚀 Quick Start

1. **Clone the repository:**
   ```bash
   git clone https://github.com/CarlesRa/godot-base-project.git
   cd godot-base-project
   ```
2. **Open the project** with Godot 4 (import `project.godot`).
3. **Try the sandbox:** open `sandbox/test_player.tscn` and run it with `F6`.

### Controls

| Action       | Keys          |
|--------------|---------------|
| `move_left`  | `A` / `←`     |
| `move_right` | `D` / `→`     |
| `jump`       | `Space` / `W` |

Keys are bound by physical position, so they work on any keyboard layout.

---

## 📁 Project Structure

```
res://
├── _autoload/            EventBus (registered); other autoloads are placeholders
├── _common/
│   └── state_machine/    Reusable State and StateMachine
├── entities/
│   └── player/           Player scene and script
│       └── states/       Player states
├── sandbox/              Test scenes for quick iteration
└── ui/ levels/ assets/   (planned)
```

**Conventions**

* Whatever is used by a single entity lives with that entity.
* Code moves to `_common/` only when it is used in two or more places.
* Scripts live next to their scene.
* A leading `_` means infrastructure (folders) or private / unused (code).
* Autoloads are added only when needed.

---

## 🧠 Architecture

### State machine

* `State` is a base class (acts as an abstract contract) that concrete states **inherit** from.
* `StateMachine` is a node that is **instanced** once per entity. It discovers its child `State` nodes, calls `setup(actor)` on each one (returns `false` if the state cannot be set up), and connects their `change_state` signal.
* States request transitions by **node name** (`StringName`). Each entity keeps its names in a constants class (e.g. `PlayerStates`), and the values must match the node names in the scene.
* States only modify `velocity`. The entity calls `move_and_slide()` **once per frame** in `_physics_process`.
* Errors are reported with `push_error` + `assert(false, msg)` (debug only), and the machine recovers to `initial_state`.

### Player

```
State
└── PlayerState        (casts actor to Player, shared horizontal movement)
    ├── PlayerIdleState
    ├── PlayerMoveState
    ├── PlayerJumpState
    └── PlayerFallState
```

* Gravity is applied in `Player._physics_process` and read from `physics/2d/default_gravity`.
* `PlayerState` exposes `_apply_horizontal_movement()`, shared by `Move`, `Jump` and `Fall`.
* Exit conditions are checked **before** the state logic, and every `emit` is followed by a `return`.
* `Fall` emits `player_landed` when the player touches the ground; `Jump` emits `player_jumped` on enter.
* Tunable values (`move_speed`, `jump_velocity`) are `@export` variables on the Player.

### EventBus

* Autoload that holds signals only, no logic.
* States emit (`EventBus.player_jumped`, `EventBus.player_landed`); whoever needs them listens.
* `sandbox/event_bus_logger.gd` prints every signal, to check the bus end to end.

### Collision layers

| Layer | Name     | Used by                    |
|-------|----------|----------------------------|
| 1     | `world`  | Ground and static geometry |
| 2     | `player` | Player (mask: `world`)     |

---

## 🧪 Debugging

Enable `debug` on a `StateMachine` node to log every transition (`change state to X`) in the console. Leave it disabled when committing.

---

## 🤝 Workflow

* Branches: `feat/...`, merged into `main` with `git merge --ff-only` (linear history). Pull requests are optional while working solo and recommended for teams.
* Commits follow [Conventional Commits](https://www.conventionalcommits.org/).
* `git pull --rebase` to keep history linear.
* `.uid` files are committed.
* Enable "Trim Trailing Whitespace on Save" and "Ensure Newline at End of File" in Editor Settings > Text Editor > Behavior > Files (editor settings are not stored in the repo).
* Optional: run `gdformat` / `gdlint` (gdtoolkit) locally or in CI.

---

## 🗺️ Roadmap

- [x] StateMachine and State base classes
- [x] Player: idle, move, jump, fall
- [x] Named collision layers
- [x] EventBus with first signals
- [x] `.editorconfig`
- [ ] GDScript warnings (`untyped_declaration`)
- [ ] Terminal velocity
- [ ] Jump buffering and coyote time
- [ ] `audio_manager` as first bus consumer
- [ ] `ui/` and `levels/`
- [ ] `scene_manager` and `game_manager`
# mantle
