# Rabbit Developer Console

<img src="plugin_icon.png" width="64" height="64" alt="Developer Console icon">

A Godot 4 in-game developer console with a Linux terminal theme. Press <kbd>~</kbd> to open it during gameplay and execute commands.

**Requires Godot 4.3+**

---

## Features

- **Terminal-style UI** — dark background, green text, bash-like prompt
- **Built-in commands** — help, clear, calc, echo, pause/unpause, mute/unmute, volume control, scene restart, and more
- **Custom commands** — register your own commands from any script
- **Autocomplete** — press <kbd>Tab</kbd> to cycle through matching commands and parameters
- **Command history** — <kbd>Up</kbd>/<kbd>Down</kbd> arrows to recall previous input, persisted across sessions
- **Font scaling** — <kbd>Ctrl</kbd>+scroll wheel to resize text on the fly
- **Fullscreen toggle** — <kbd>Ctrl</kbd>+<kbd>~</kbd> to expand the console
- **Custom themes** — set a `.tres` theme via Project Settings (`console/theme`)

---

## Install

### Manual

1. Copy `addons/rabbit_developer_console/` into your project:
   ```
   your_project/
   └── addons/
       └── rabbit_developer_console/
           ├── plugin.cfg
           ├── rabbit_console_plugin.gd
           ├── rabbit_console.gd
           └── builtin_commands.gd
   ```
2. **Project → Project Settings → Plugins** → enable **Developer Console**

---

## Usage

Press <kbd>~</kbd> (backtick/tilde) during gameplay to open the console.

### Key Bindings

| Key | Action |
|---|---|
| <kbd>~</kbd> | Toggle console |
| <kbd>Esc</kbd> | Close console |
| <kbd>Ctrl</kbd>+<kbd>~</kbd> | Toggle fullscreen console |
| <kbd>Tab</kbd> | Autocomplete (press again to cycle) |
| <kbd>Up</kbd> / <kbd>Down</kbd> | Navigate command history |
| <kbd>PageUp</kbd> / <kbd>PageDown</kbd> | Scroll output |
| <kbd>Ctrl</kbd>+Scroll | Adjust font size |

### Built-in Commands

| Command | Description |
|---|---|
| `help` | Show help and key bindings |
| `commands` | List all available commands |
| `commands_list` | List commands with usage details |
| `clear` | Clear console output |
| `echo <string>` | Print text to console |
| `calc <expr>` | Evaluate a math expression |
| `exec <filename>` | Run commands from a `user://<filename>.txt` script |
| `pause` / `unpause` | Pause or resume the scene tree |
| `restart` / `reload` | Restart the current scene |
| `mute` / `unmute` | Toggle audio |
| `volume <0.0-1.0>` | Set master volume |
| `volume_up` / `volume_down` | Adjust volume by 10% |
| `quit` / `exit` | Quit the game |
| `delete_history` | Clear command history |

---

## Adding Custom Commands

Register commands from any script that has access to the `Console` autoload:

```gdscript
func _ready():
    Console.add_command("greet", greet, ["name"], 1, "Greets someone by name.")

func greet(player_name: String) -> void:
    Console.print_line("Hello, %s!" % player_name)
```

### API Reference

```gdscript
# Add a command (arguments can be an Array of names or an int for legacy support)
Console.add_command(name: String, function: Callable, arguments = [], required: int = 0, description: String = "")

# Add a hidden command (won't appear in help or autocomplete)
Console.add_hidden_command(name: String, function: Callable, arguments = [], required: int = 0)

# Remove a command (call in _exit_tree if the node may be freed)
Console.remove_command(name: String)

# Add autocomplete suggestions for a command's parameters
Console.add_command_autocomplete_list(name: String, param_list: PackedStringArray)

# Output helpers
Console.print_line(text)
Console.print_error(text)
Console.print_warning(text)
Console.print_info(text)

# Console control
Console.toggle_console()
Console.enable()
Console.disable()
```

### Signals

```gdscript
Console.console_opened       # Emitted when the console is shown
Console.console_closed       # Emitted when the console is hidden
Console.console_unknown_command  # Emitted when an unrecognized command is entered
```

### Properties

```gdscript
Console.enabled: bool                   # Enable/disable the console
Console.enable_on_release_build: bool   # Allow console in release builds
Console.pause_enabled: bool             # Pause the game while console is open
Console.font_size: int                  # Override font size (-1 for default)
```

---

## Credits

Made by [Lost Rabbit Digital](https://lostrabbit.digital/) · [Discord](https://discord.gg/Y7caBf7gBj)

MIT — see [LICENSE](LICENSE)

---

<div align="center">

## Special Thanks

<br>

### A huge thank you to [jitspoe](https://github.com/jitspoe) and the [Godot Console](https://github.com/jitspoe/godot-console) project!

This plugin was built upon and inspired by their fantastic work.
Their open-source developer console laid the foundation that made this project possible.

If you're looking for the original, check it out:

[![jitspoe/godot-console](https://img.shields.io/badge/GitHub-jitspoe%2Fgodot--console-181717?style=for-the-badge&logo=github&logoColor=white)](https://github.com/jitspoe/godot-console)

<br>

</div>
