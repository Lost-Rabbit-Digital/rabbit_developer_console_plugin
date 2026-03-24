# Godot Developer Console — Auto-Discovery Debug Command Generator

> **How to use:** Feed this entire prompt to Claude or another LLM while it has
> access to your Godot project files. The model will scan your project
> automatically — no manual "project context" section needed. It will then
> generate a complete `debug_console_commands.gd` file with relevant
> `Console.add_command(...)` registrations ready to drop into your project.

---

## PROMPT

You are an expert Godot 4.x GDScript developer. I am using the **Rabbit
Developer Console** addon (by Lost Rabbit Digital, based on Jitspoe's original
work) in my Godot project.

### Step 0 — Discover the Project

Before generating any code, **scan the project to build context automatically**.
Perform each of the following discovery steps and record what you find:

1. **`project.godot`** — Read it. Extract:
   - Project name, version, tags, features, min engine version
   - All `[autoload]` entries (singleton names and paths)
   - Any custom project settings
   - The main scene path

2. **Scene files (`.tscn` / `.scn`)** — List every scene file in the project.
   Note scene names, directory structure, and any that look like levels/maps.

3. **GDScript files (`.gd`)** — List all script files. For each, read the
   `extends` line and the `class_name` (if any). Flag scripts that extend
   common base types: `CharacterBody2D/3D`, `RigidBody2D/3D`, `Node`,
   `Resource`, `Control`, `Area2D/3D`.

4. **Player script(s)** — Find any script whose filename or class name contains
   "player", "character", "hero", or "pawn". Read exported vars, properties,
   and methods. Record health, stamina, speed, position, or any stat-like
   variables.

5. **Autoload singletons** — For every autoload listed in `project.godot`, read
   the script. Record public methods, signals, and key state variables (e.g.,
   `GameState.current_level`, `PlayerData.gold`).

6. **Enemy / NPC / AI scripts** — Find scripts containing "enemy", "npc", "ai",
   "mob", "boss", or "agent". Note state machines, spawn logic, faction vars.

7. **Inventory / Economy / Crafting** — Search for scripts or resources related
   to items, inventory, currency, crafting, shops, or loot tables.

8. **UI / HUD scripts** — Identify scripts managing health bars, minimaps,
   score displays, dialogue, menus, or notifications.

9. **Audio** — Note any audio manager autoload or bus layout
   (`default_bus_layout.tres`).

10. **Shaders & visual effects** — Note any `.gdshader` files or
    `ShaderMaterial` usage that could benefit from runtime parameter tweaking.

11. **Custom resources (`.tres`)** — List any custom `Resource` subclasses that
    define game data (items, abilities, stats, wave configs, etc.).

12. **Pain points** — Look for `TODO`, `FIXME`, `HACK`, `BUG`, or `WARN`
    comments in scripts. These often indicate areas that would benefit from
    debug commands.

### Addon API Reference

The addon exposes a global `Console` autoload singleton:

```gdscript
# Register a command
# arguments: int (legacy count) OR Array of argument name strings
# required: number of mandatory arguments
# description: help text shown in commands_list
Console.add_command("command_name", callable, arguments, required, "Description")

# Register a hidden command (won't appear in help / autocomplete)
Console.add_hidden_command("command_name", callable, arguments, required)

# Remove a command (call in _exit_tree for dynamic commands)
Console.remove_command("command_name")

# Provide autocomplete suggestions for a command's parameter
Console.add_command_autocomplete_list("command_name", PackedStringArray)

# Output to console
Console.print_line("message")
Console.print_error("message")
Console.print_warning("message")
Console.print_info("message")
```

### Important Constraints

- Parameters are **always received as `String`**. Cast manually: `int(param)`,
  `float(param)`, `param.to_lower() == "true"`, etc.
- `quit` and `exit` are registered by default — do **not** re-register them.
- Commands should be registered in `_ready()`.
- All handler functions must accept the exact parameter count declared in
  `add_command`.
- Use `Console.remove_command()` in `_exit_tree()` if your debug node can be
  unloaded before the project closes.

### Your Task

Using the project context you discovered in Step 0:

1. **Identify the most useful debug command categories** for this specific
   project (e.g., player state, game state, scene management, AI/enemy
   control, economy/inventory, audio, rendering, physics, etc.).

2. **Generate a complete GDScript file** named `debug_console_commands.gd` that:
   - Extends `Node`
   - Can be added as an AutoLoad or attached to any persistent scene node
   - Registers all commands in `_ready()`
   - Removes any scene-dependent commands in `_exit_tree()` if necessary
   - Implements all handler functions below the registration block
   - Uses `Console.print_line()` / `Console.print_info()` /
     `Console.print_error()` / `Console.print_warning()` for all feedback
   - Includes autocomplete where it makes sense (scene names, item IDs,
     state names, audio bus names, etc.)
   - Groups related commands with `# --- Section ---` comments

3. **For each command**, include a brief inline comment explaining what it does
   and why it is useful for debugging this project.

4. **Always include these universal debug commands** (adapt naming and values to
   fit the project):

   | Category | Commands |
   |---|---|
   | **Scene / Level** | `load_scene <name>`, `reload`, `list_scenes` |
   | **Time** | `timescale <float>` (set `Engine.time_scale`) |
   | **Player cheats** | `god` (toggle godmode), `tp <x> <y> [z]`, `set_health <val>`, `set_speed <val>` |
   | **Logging** | `verbose` (toggle), `print_tree` (print `SceneTree`), `print_node <path>` |
   | **Performance** | `fps` (show FPS / frame time), `mem` (memory usage), `toggle_debug_overlay` |
   | **Physics** | `physics_toggle` (pause/unpause physics), `collision_layers` (print layers) |
   | **Engine info** | `engine_info` (Godot version, renderer, adapter), `list_autoloads` |

5. **Add project-specific commands** based on the game systems, mechanics,
   singletons, and nodes you discovered. Be thorough — the more useful the
   commands, the better. Examples:
   - Inventory: `give_item <id> [count]`, `clear_inventory`, `list_items`
   - Economy: `set_gold <amount>`, `add_xp <amount>`
   - AI: `kill_all`, `spawn <enemy_type>`, `set_ai_state <state>`
   - Dialogue: `trigger_dialogue <id>`, `skip_dialogue`
   - Audio: `play_sfx <name>`, `play_music <name>`
   - Save system: `save`, `load_save <slot>`, `delete_save <slot>`

6. **After the code block**, provide a Markdown table summarizing every
   registered command with columns: **Command**, **Parameters**,
   **Description**.

### Output Format

````
```gdscript
# debug_console_commands.gd
# Add as AutoLoad or attach to a persistent scene node.
extends Node

func _ready() -> void:
    # --- Universal ---
    Console.add_command(...)
    ...

    # --- [Project-Specific Section] ---
    Console.add_command(...)
    ...

# =====================
# Handlers
# =====================

func ...
```
````

Then the Markdown summary table.
