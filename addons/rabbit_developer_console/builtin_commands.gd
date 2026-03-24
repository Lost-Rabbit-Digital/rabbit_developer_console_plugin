extends RefCounted
## Built-in commands for the Rabbit Developer Console.
## This file registers all default commands provided by the console.

var console : Node


func _init(in_console : Node) -> void:
	console = in_console


func register_all() -> void:
	# General
	console.add_command("quit", quit, 0, 0, "Quits the game.")
	console.add_command("exit", quit, 0, 0, "Quits the game.")
	console.add_command("clear", clear, 0, 0, "Clears the text on the console.")
	console.add_command("delete_history", delete_history, 0, 0, "Deletes the history of previously entered commands.")
	console.add_command("help", help, ["command"], 0, "Displays instructions on how to use the console. Pass a command name for detailed help.")
	console.add_command("commands_list", commands_list, 0, 0, "Lists all commands and their descriptions.")
	console.add_command("commands", commands, 0, 0, "Lists commands with no descriptions.")
	console.add_command("close", close, 0, 0, "Closes the console window.")
	console.add_command("discord", discord, 0, 0, "Prints the link to the Rabbit Developer Console Discord server.")

	# Output
	console.add_command("echo", console.print_line, ["string"], 1, "Prints given string to the console.")
	console.add_command("echo_warning", console.print_warning, ["string"], 1, "Prints given string as warning to the console.")
	console.add_command("echo_info", console.print_info, ["string"], 1, "Prints given string as info to the console.")
	console.add_command("echo_error", console.print_error, ["string"], 1, "Prints given string as an error to the console.")

	# Utility
	console.add_command("calc", calculate, ["mathematical expression to evaluate"], 0, "Evaluates the math passed in for quick arithmetic.")
	console.add_command("exec", exec, ["filename"], 1, "Execute a script.")
	console.add_command("list_scripts", list_scripts, 0, 0, "Lists all script .txt files in the user:// directory.")

	# Scene management
	console.add_command("pause", pause, 0, 0, "Pauses node processing.")
	console.add_command("unpause", unpause, 0, 0, "Unpauses node processing.")
	console.add_command("restart", restart_scene, 0, 0, "Restarts the current scene.")
	console.add_command("reload", restart_scene, 0, 0, "Restarts the current scene.")

	# Display
	console.add_command("console_full", console_full, 0, 0, "Sets the console to full window mode.")
	console.add_command("console_bottom", console_bottom, 0, 0, "Docks the console to the bottom half.")
	console.add_command("console_top", console_top, 0, 0, "Docks the console to the top half.")
	console.add_command("console_left", console_left, 0, 0, "Docks the console to the left half.")
	console.add_command("console_right", console_right, 0, 0, "Docks the console to the right half.")
	console.add_command("console_upper_left", console_upper_left, 0, 0, "Docks the console to the upper left corner.")
	console.add_command("console_upper_right", console_upper_right, 0, 0, "Docks the console to the upper right corner.")
	console.add_command("console_lower_left", console_lower_left, 0, 0, "Docks the console to the lower left corner.")
	console.add_command("console_lower_right", console_lower_right, 0, 0, "Docks the console to the lower right corner.")
	console.add_command("transparency", transparency, ["level 0-100"], 1, "Sets console background transparency (0=opaque, 100=invisible).")

	# Time
	console.add_command("timescale", set_timescale, ["speed"], 1, "Sets Engine.time_scale (e.g. 0.5, 2.0).")

	# Performance / Engine
	console.add_command("fps", fps, 0, 0, "Prints current FPS and frame time.")
	console.add_command("mem", mem, 0, 0, "Prints memory usage.")
	console.add_command("engine_info", engine_info, 0, 0, "Prints Godot version, renderer, and adapter info.")
	console.add_command("vsync", set_vsync, ["mode"], 0, "Gets or sets VSync mode (disabled, enabled, adaptive, mailbox).")
	var vsync_modes := PackedStringArray(["disabled", "enabled", "adaptive", "mailbox"])
	console.add_command_autocomplete_list("vsync", vsync_modes)

	# Scene tree / Node inspection
	console.add_command("print_tree", print_tree_cmd, 0, 0, "Prints the current scene tree.")
	console.add_command("print_node", print_node, ["node_path"], 1, "Prints details about a node at the given path.")
	console.add_command("list_scenes", list_scenes, 0, 0, "Lists all .tscn files in the project.")
	console.add_command("load_scene", load_scene, ["scene_path"], 1, "Changes to the given scene (res:// path or name).")
	console.add_command("list_autoloads", list_autoloads, 0, 0, "Lists all autoload singletons.")
	console.add_command("scene_info", scene_info, 0, 0, "Prints info about the current scene.")

	# Physics
	console.add_command("physics_toggle", physics_toggle, 0, 0, "Toggles physics processing on/off.")

	# Audio
	console.add_command("mute", mute, 0, 0, "Mutes all game audio.")
	console.add_command("unmute", unmute, 0, 0, "Unmutes all game audio.")
	console.add_command("volume", set_volume, ["level 0.0-1.0"], 1, "Sets master volume (0.0 to 1.0).")
	console.add_command("volume_up", volume_up, 0, 0, "Increases master volume by 10%.")
	console.add_command("volume_down", volume_down, 0, 0, "Decreases master volume by 10%.")
	console.add_command("list_buses", list_audio_buses, 0, 0, "Lists all audio buses and their volumes.")


# ---- General ----

func quit() -> void:
	console.get_tree().quit()


func close() -> void:
	console.toggle_console()


func clear() -> void:
	console.rich_label.clear()


func delete_history() -> void:
	console.console_history.clear()
	console.console_history_index = 0
	DirAccess.remove_absolute("user://console_history.txt")


func discord() -> void:
	console.print_line("Join the Rabbit Developer Console Discord: [url=https://discord.gg/Y7caBf7gBj]https://discord.gg/Y7caBf7gBj[/url]")

func help(command_name: String = "") -> void:
	if not command_name.is_empty():
		_show_command_help(command_name.to_lower().strip_edges().replace(" ", "_"))
		return
	console.rich_label.append_text("[color=#ffff55]BUILT-IN COMMANDS[/color]\n[color=#888888]  Use [/color][color=#00ff00]help <command>[/color][color=#888888] for detailed help on any command.[/color]
[color=#888888]  Click any command name to view its help page.[/color]

[color=#888888]  General[/color]
  [meta=cmd://clear][color=#00ff00]clear[/color][/meta]            Clear the terminal screen
  [meta=cmd://commands][color=#00ff00]commands[/color][/meta]         List available commands
  [meta=cmd://commands_list][color=#00ff00]commands list[/color][/meta]    List commands with usage details
  [meta=cmd://delete_history][color=#00ff00]delete history[/color][/meta]   Clear command history
  [meta=cmd://discord][color=#00ff00]discord[/color][/meta]          Show the Discord server link
  [meta=cmd://help][color=#00ff00]help[/color][/meta]             Show this help message
  [meta=cmd://quit][color=#00ff00]quit[/color][/meta] / [meta=cmd://quit][color=#00ff00]exit[/color][/meta]     Terminate the application

[color=#888888]  Output[/color]
  [meta=cmd://echo][color=#00ff00]echo[/color][/meta]             Print a string to stdout
  [meta=cmd://echo_error][color=#00ff00]echo error[/color][/meta]       Print a string to stderr
  [meta=cmd://echo_info][color=#00ff00]echo info[/color][/meta]        Print an info message
  [meta=cmd://echo_warning][color=#00ff00]echo warning[/color][/meta]     Print a warning message

[color=#888888]  Utility[/color]
  [meta=cmd://calc][color=#00ff00]calc[/color][/meta]             Evaluate a mathematical expression
  [meta=cmd://exec][color=#00ff00]exec[/color][/meta]             Execute commands from a script file

[color=#888888]  Display[/color]
  [meta=cmd://console_full][color=#00ff00]console full[/color][/meta]     Set console to full window mode
  [meta=cmd://console_bottom][color=#00ff00]console bottom[/color][/meta]   Dock console to bottom half
  [meta=cmd://console_top][color=#00ff00]console top[/color][/meta]      Dock console to top half
  [meta=cmd://console_left][color=#00ff00]console left[/color][/meta]     Dock console to left half
  [meta=cmd://console_right][color=#00ff00]console right[/color][/meta]    Dock console to right half
  [meta=cmd://console_upper_left][color=#00ff00]console upper left[/color][/meta]  Dock console to upper left corner
  [meta=cmd://console_upper_right][color=#00ff00]console upper right[/color][/meta] Dock console to upper right corner
  [meta=cmd://console_lower_left][color=#00ff00]console lower left[/color][/meta]  Dock console to lower left corner
  [meta=cmd://console_lower_right][color=#00ff00]console lower right[/color][/meta] Dock console to lower right corner
  [meta=cmd://transparency][color=#00ff00]transparency[/color][/meta]     Set background transparency (0-100)

[color=#888888]  Time[/color]
  [meta=cmd://timescale][color=#00ff00]timescale[/color][/meta]        Set Engine.time_scale (e.g. 0.5, 2.0)

[color=#888888]  Scene[/color]
  [meta=cmd://pause][color=#00ff00]pause[/color][/meta] / [meta=cmd://pause][color=#00ff00]unpause[/color][/meta]  Toggle node processing
  [meta=cmd://restart][color=#00ff00]restart[/color][/meta] / [meta=cmd://restart][color=#00ff00]reload[/color][/meta] Restart the current scene
  [meta=cmd://load_scene][color=#00ff00]load scene[/color][/meta]       Change to a scene by path or name
  [meta=cmd://list_scenes][color=#00ff00]list scenes[/color][/meta]      List all .tscn files in the project
  [meta=cmd://scene_info][color=#00ff00]scene info[/color][/meta]       Info about the current scene

[color=#888888]  Inspection[/color]
  [meta=cmd://print_tree][color=#00ff00]print tree[/color][/meta]       Print the current scene tree
  [meta=cmd://print_node][color=#00ff00]print node[/color][/meta]       Print details about a node at a path
  [meta=cmd://list_autoloads][color=#00ff00]list autoloads[/color][/meta]   List all autoload singletons
  [meta=cmd://engine_info][color=#00ff00]engine info[/color][/meta]      Godot version, renderer, adapter info

[color=#888888]  Performance[/color]
  [meta=cmd://fps][color=#00ff00]fps[/color][/meta]              Show FPS and frame time
  [meta=cmd://mem][color=#00ff00]mem[/color][/meta]              Show memory usage
  [meta=cmd://vsync][color=#00ff00]vsync[/color][/meta]            Get or set VSync mode
  [meta=cmd://physics_toggle][color=#00ff00]physics toggle[/color][/meta]   Toggle physics processing on/off

[color=#888888]  Audio[/color]
  [meta=cmd://mute][color=#00ff00]mute[/color][/meta] / [meta=cmd://mute][color=#00ff00]unmute[/color][/meta]   Toggle game audio
  [meta=cmd://volume][color=#00ff00]volume[/color][/meta]           Set master volume (0.0-1.0)
  [meta=cmd://volume_up][color=#00ff00]volume up[/color][/meta] / [meta=cmd://volume_down][color=#00ff00]down[/color][/meta] Adjust volume by 10%%
  [meta=cmd://list_buses][color=#00ff00]list buses[/color][/meta]       List all audio buses

[color=#ffff55]KEY BINDINGS[/color]
  [color=#5555ff]Up/Down[/color]           Navigate command history
  [color=#5555ff]PageUp/PageDown[/color]   Scroll output buffer
  [color=#5555ff]Tab[/color]              Auto-complete; press again to cycle
  [color=#5555ff]Ctrl+~[/color]           Cycle console position
  [color=#5555ff]Ctrl+[[/color]           Decrease transparency
  [color=#5555ff]Ctrl+][/color]           Increase transparency
  [color=#5555ff]Ctrl+Scroll[/color]      Adjust font size
  [color=#5555ff]~ / Esc[/color]          Close console
")


func commands() -> void:
	var cmds := []
	for command in console.console_commands:
		if (!console.console_commands[command].hidden):
			cmds.append(command)
	cmds.sort()
	var line := ""
	for i in range(cmds.size()):
		line += "[meta=cmd://%s][color=#00ff00]%s[/color][/meta]" % [cmds[i], cmds[i].replace("_", " ")]
		if i < cmds.size() - 1:
			line += "  "
	console.rich_label.append_text(line + "\n")


func commands_list() -> void:
	var cmds := []
	for command in console.console_commands:
		if (!console.console_commands[command].hidden):
			cmds.append(str(command))
	cmds.sort()

	for command in cmds:
		var command_display: String = command.replace("_", " ")
		var arguments_string := ""
		var description : String = console.console_commands[command].description
		for i in range(console.console_commands[command].arguments.size()):
			if i < console.console_commands[command].required:
				arguments_string += " [color=#5555ff]<" + console.console_commands[command].arguments[i] + ">[/color]"
			else:
				arguments_string += " [color=#666666][" + console.console_commands[command].arguments[i] + "][/color]"
		console.rich_label.append_text("  [meta=cmd://%s][color=#00ff00]%-18s[/color][/meta]%s  [color=#888888]%s[/color]\n" % [command, command_display, arguments_string, description])
	console.rich_label.append_text("\n")


# ---- Utility ----

func calculate(command : String) -> void:
	var expression := Expression.new()
	var error = expression.parse(command)
	if error:
		console.print_error("%s" % expression.get_error_text())
		return
	var result = expression.execute()
	if not expression.has_execute_failed():
		console.print_line(str(result))
	else:
		console.print_error("%s" % expression.get_error_text())


func exec(filename : String) -> void:
	var path := "user://%s.txt" % [filename]
	var script := FileAccess.open(path, FileAccess.READ)
	if (script):
		while (!script.eof_reached()):
			console._on_text_entered(script.get_line())
	else:
		console.print_error("%s: No such file or directory" % [path])


func list_scripts() -> void:
	var dir := DirAccess.open("user://")
	if not dir:
		console.print_warning("Could not open user:// directory.")
		return
	var scripts : PackedStringArray
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name:
		if not dir.current_is_dir() and file_name.ends_with(".txt") and file_name != "console_history.txt":
			scripts.append(file_name)
		file_name = dir.get_next()
	if scripts.is_empty():
		console.print_warning("No script files found in user://")
		return
	console.print_line("[color=#ffff55]SCRIPTS (%d)[/color]" % scripts.size())
	for script in scripts:
		console.print_line("  %s" % script)


# ---- Display ----

func console_full() -> void:
	console.set_console_position(console.ConsolePosition.FULL)
	console.print_info("Console set to full window mode.")


func console_bottom() -> void:
	console.set_console_position(console.ConsolePosition.BOTTOM)
	console.print_info("Console docked to bottom.")


func console_top() -> void:
	console.set_console_position(console.ConsolePosition.TOP)
	console.print_info("Console docked to top.")


func console_left() -> void:
	console.set_console_position(console.ConsolePosition.LEFT)
	console.print_info("Console docked to left.")


func console_right() -> void:
	console.set_console_position(console.ConsolePosition.RIGHT)
	console.print_info("Console docked to right.")


func console_upper_left() -> void:
	console.set_console_position(console.ConsolePosition.UPPER_LEFT)
	console.print_info("Console docked to upper left corner.")


func console_upper_right() -> void:
	console.set_console_position(console.ConsolePosition.UPPER_RIGHT)
	console.print_info("Console docked to upper right corner.")


func console_lower_left() -> void:
	console.set_console_position(console.ConsolePosition.LOWER_LEFT)
	console.print_info("Console docked to lower left corner.")


func console_lower_right() -> void:
	console.set_console_position(console.ConsolePosition.LOWER_RIGHT)
	console.print_info("Console docked to lower right corner.")


func transparency(level : String) -> void:
	if not level.is_valid_float():
		console.print_error("transparency: '%s' is not a valid number (expected 0-100)" % level)
		return
	var value := clampf(level.to_float(), 0.0, 100.0)
	console.set_bg_transparency(1.0 - value / 100.0)
	console.print_info("Background transparency set to %d%%." % int(value))


# ---- Scene management ----

func pause() -> void:
	console.get_tree().paused = true


func unpause() -> void:
	console.get_tree().paused = false


func restart_scene() -> void:
	console.get_tree().reload_current_scene()
	console.print_info("Scene restarted.")


# ---- Audio ----

func _get_master_bus_index() -> int:
	return AudioServer.get_bus_index("Master")


func mute() -> void:
	var bus := _get_master_bus_index()
	AudioServer.set_bus_mute(bus, true)
	console.print_info("Audio muted.")


func unmute() -> void:
	var bus := _get_master_bus_index()
	AudioServer.set_bus_mute(bus, false)
	console.print_info("Audio unmuted.")


func set_volume(level : String) -> void:
	if not level.is_valid_float():
		console.print_error("volume: '%s' is not a valid number (expected 0.0-1.0)" % level)
		return
	var value := clampf(level.to_float(), 0.0, 1.0)
	var bus := _get_master_bus_index()
	AudioServer.set_bus_volume_db(bus, linear_to_db(value))
	if value == 0.0:
		AudioServer.set_bus_mute(bus, true)
	else:
		AudioServer.set_bus_mute(bus, false)
	console.print_info("Master volume set to %d%%." % int(value * 100))


func volume_up() -> void:
	var bus := _get_master_bus_index()
	var current := db_to_linear(AudioServer.get_bus_volume_db(bus))
	var value := clampf(current + 0.1, 0.0, 1.0)
	AudioServer.set_bus_volume_db(bus, linear_to_db(value))
	if AudioServer.is_bus_mute(bus) and value > 0.0:
		AudioServer.set_bus_mute(bus, false)
	console.print_info("Master volume: %d%%." % int(value * 100))


func volume_down() -> void:
	var bus := _get_master_bus_index()
	var current := db_to_linear(AudioServer.get_bus_volume_db(bus))
	var value := clampf(current - 0.1, 0.0, 1.0)
	AudioServer.set_bus_volume_db(bus, linear_to_db(value))
	console.print_info("Master volume: %d%%." % int(value * 100))


func list_audio_buses() -> void:
	console.print_line("[color=#ffff55]AUDIO BUSES[/color]")
	for i in range(AudioServer.bus_count):
		var name := AudioServer.get_bus_name(i)
		var vol := db_to_linear(AudioServer.get_bus_volume_db(i))
		var muted := AudioServer.is_bus_mute(i)
		var send := AudioServer.get_bus_send(i)
		var status := " [color=#ff4444](muted)[/color]" if muted else ""
		var send_info := " -> %s" % send if send else ""
		console.print_line("  [color=#00ff00]%s[/color]  %d%%%s%s" % [name, int(vol * 100), status, send_info])


# ---- Time ----

func set_timescale(speed : String) -> void:
	if not speed.is_valid_float():
		console.print_error("timescale: '%s' is not a valid number" % speed)
		return
	var value := maxf(speed.to_float(), 0.0)
	Engine.time_scale = value
	console.print_info("Time scale set to %.2f." % value)


# ---- Performance / Engine ----

func fps() -> void:
	var current_fps := Engine.get_frames_per_second()
	var frame_time := 1000.0 / maxf(current_fps, 1)
	console.print_line("[color=#ffff55]FPS:[/color] %d  [color=#ffff55]Frame time:[/color] %.2f ms" % [current_fps, frame_time])


func mem() -> void:
	var static_mem := OS.get_static_memory_usage()
	var static_peak := OS.get_static_memory_peak_usage()
	console.print_line("[color=#ffff55]MEMORY USAGE[/color]")
	console.print_line("  Static:  %s" % String.humanize_size(static_mem))
	console.print_line("  Peak:    %s" % String.humanize_size(static_peak))
	if OS.has_feature("debug"):
		var objects := Performance.get_monitor(Performance.OBJECT_COUNT)
		var nodes := Performance.get_monitor(Performance.OBJECT_NODE_COUNT)
		var orphans := Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)
		var resources := Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT)
		console.print_line("  Objects: %d  Nodes: %d  Orphans: %d  Resources: %d" % [objects, nodes, orphans, resources])


func engine_info() -> void:
	var version := Engine.get_version_info()
	console.print_line("[color=#ffff55]ENGINE INFO[/color]")
	console.print_line("  Godot:      %s.%s.%s %s" % [version.major, version.minor, version.patch, version.status])
	console.print_line("  Project:    %s v%s" % [
		ProjectSettings.get_setting("application/config/name", "Unknown"),
		ProjectSettings.get_setting("application/config/version", "?"),
	])
	console.print_line("  Renderer:   %s" % ProjectSettings.get_setting("rendering/renderer/rendering_method", "unknown"))
	var adapter := RenderingServer.get_video_adapter_name()
	if adapter:
		console.print_line("  Adapter:    %s" % adapter)
	console.print_line("  OS:         %s %s" % [OS.get_name(), OS.get_version()])
	console.print_line("  Debug:      %s" % str(OS.is_debug_build()))


func set_vsync(mode : String) -> void:
	if mode.is_empty():
		var current := DisplayServer.window_get_vsync_mode()
		var names := {0: "disabled", 1: "enabled", 2: "adaptive", 3: "mailbox"}
		console.print_info("VSync: %s" % names.get(current, "unknown"))
		return
	var modes := {"disabled": 0, "enabled": 1, "adaptive": 2, "mailbox": 3}
	var lower := mode.to_lower()
	if not modes.has(lower):
		console.print_error("vsync: unknown mode '%s'. Use: disabled, enabled, adaptive, mailbox" % mode)
		return
	DisplayServer.window_set_vsync_mode(modes[lower])
	console.print_info("VSync set to %s." % lower)


# ---- Scene tree / Node inspection ----

func print_tree_cmd() -> void:
	var root := console.get_tree().current_scene
	if not root:
		console.print_warning("No current scene.")
		return
	console.print_line("[color=#ffff55]SCENE TREE[/color]: %s" % root.scene_file_path)
	_print_node_recursive(root, "")


func _print_node_recursive(node : Node, indent : String) -> void:
	var type_color := "#5555ff"
	var node_path := str(console.get_tree().current_scene.get_path_to(node))
	var name_str := "[url=node://%s][color=#00ff00]%s[/color] [color=%s](%s)[/color][/url]" % [node_path, node.name, type_color, node.get_class()]
	if node.scene_file_path and node != console.get_tree().current_scene:
		name_str += " [color=#666666]@ %s[/color]" % node.scene_file_path
	console.print_line("%s%s" % [indent, name_str])
	for child in node.get_children():
		_print_node_recursive(child, indent + "  ")


func print_node(node_path : String) -> void:
	var root := console.get_tree().current_scene
	if not root:
		console.print_warning("No current scene.")
		return
	var node := root.get_node_or_null(node_path)
	if not node:
		# Try absolute path
		node = console.get_tree().root.get_node_or_null(node_path)
	if not node:
		console.print_error("Node not found: %s" % node_path)
		return
	console.print_line("[color=#ffff55]NODE:[/color] %s [color=#5555ff](%s)[/color]" % [node.name, node.get_class()])
	console.print_line("  Path:     %s" % str(node.get_path()))
	console.print_line("  Owner:    %s" % (str(node.owner.name) if node.owner else "none"))
	console.print_line("  Children: %d" % node.get_child_count())
	if node.scene_file_path:
		console.print_line("  Scene:    %s" % node.scene_file_path)
	if node is Node2D:
		console.print_line("  Position: %s" % str(node.global_position))
	elif node is Node3D:
		console.print_line("  Position: %s" % str(node.global_position))
	# List exported properties via script
	var script : Script = node.get_script()
	if script:
		console.print_line("  Script:   %s" % script.resource_path)
		var props := node.get_property_list()
		var script_props := []
		for prop in props:
			if prop.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
				script_props.append("    %s = %s" % [prop.name, str(node.get(prop.name))])
		if script_props.size():
			console.print_line("  [color=#ffff55]Script vars:[/color]")
			for line in script_props:
				console.print_line(line)


func list_scenes() -> void:
	var scenes := _find_files_recursive("res://", ".tscn")
	if scenes.is_empty():
		console.print_warning("No .tscn files found.")
		return
	console.print_line("[color=#ffff55]SCENES (%d)[/color]" % scenes.size())
	for scene in scenes:
		console.print_line("  %s" % scene)


func _find_files_recursive(path : String, extension : String) -> PackedStringArray:
	var results : PackedStringArray
	var dir := DirAccess.open(path)
	if not dir:
		return results
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name:
		var full_path := path.path_join(file_name)
		if dir.current_is_dir():
			if not file_name.begins_with(".") and file_name != "addons":
				results.append_array(_find_files_recursive(full_path, extension))
		elif file_name.ends_with(extension):
			results.append(full_path)
		file_name = dir.get_next()
	return results


func load_scene(scene_path : String) -> void:
	var full_path := scene_path
	if not scene_path.begins_with("res://"):
		full_path = "res://%s" % scene_path
	if not full_path.ends_with(".tscn"):
		full_path += ".tscn"
	if not ResourceLoader.exists(full_path):
		console.print_error("Scene not found: %s" % full_path)
		return
	var err := console.get_tree().change_scene_to_file(full_path)
	if err == OK:
		console.print_info("Loading scene: %s" % full_path)
	else:
		console.print_error("Failed to load scene: %s (error %d)" % [full_path, err])


func list_autoloads() -> void:
	console.print_line("[color=#ffff55]AUTOLOADS[/color]")
	var root := console.get_tree().root
	for child in root.get_children():
		if child == console.get_tree().current_scene:
			continue
		var script : Script = child.get_script()
		var script_path := script.resource_path if script else "built-in"
		console.print_line("  [color=#00ff00]%s[/color] [color=#5555ff](%s)[/color] %s" % [child.name, child.get_class(), script_path])


func scene_info() -> void:
	var scene := console.get_tree().current_scene
	if not scene:
		console.print_warning("No current scene.")
		return
	console.print_line("[color=#ffff55]CURRENT SCENE[/color]")
	console.print_line("  Name:     %s" % scene.name)
	console.print_line("  Path:     %s" % scene.scene_file_path)
	console.print_line("  Type:     %s" % scene.get_class())
	var count := _count_nodes(scene)
	console.print_line("  Nodes:    %d" % count)


func _count_nodes(node : Node) -> int:
	var count := 1
	for child in node.get_children():
		count += _count_nodes(child)
	return count


# ---- Command help pages ----

func _show_command_help(command_name: String) -> void:
	var pages := _build_help_pages()
	# Resolve aliases to their canonical entry
	var aliases := {"exit": "quit", "reload": "restart", "unmute": "mute",
		"volume_up": "volume", "volume_down": "volume",
		"echo_warning": "echo", "echo_info": "echo", "echo_error": "echo",
		"console_bottom": "console_full", "console_top": "console_full",
		"console_left": "console_full", "console_right": "console_full",
		"console_upper_left": "console_full", "console_upper_right": "console_full",
		"console_lower_left": "console_full", "console_lower_right": "console_full"}
	var key := aliases.get(command_name, command_name)
	if pages.has(key):
		console.rich_label.append_text(pages[key])
	elif console.console_commands.has(command_name):
		var cmd = console.console_commands[command_name]
		var display := command_name.replace("_", " ")
		var args_str := ""
		for i in range(cmd.arguments.size()):
			if i < cmd.required:
				args_str += " [color=#5555ff]<%s>[/color]" % cmd.arguments[i]
			else:
				args_str += " [color=#666666][%s][/color]" % cmd.arguments[i]
		console.rich_label.append_text("[color=#ffff55]HELP: %s[/color]\n\n  [color=#00ff00]%s[/color]%s\n\n  %s\n\n" % [display, display, args_str, cmd.description])
	else:
		console.print_error("help: no entry for '%s'. Try [meta=cmd://commands][color=#00ff00]commands[/color][/meta] to list all commands." % command_name.replace("_", " "))


func _build_help_pages() -> Dictionary:
	return {
# ---- General ----
"quit": """[color=#ffff55]QUIT[/color]                                          [color=#888888]general[/color]

  [color=#00ff00]quit[/color]  [color=#888888]alias:[/color] [color=#00ff00]exit[/color]

[color=#ffff55]DESCRIPTION[/color]
  Immediately terminates the application. Equivalent to calling
  [color=#888888]get_tree().quit()[/color] in GDScript.

[color=#ffff55]USAGE[/color]
  [color=#00ff00]quit[/color]
  [color=#00ff00]exit[/color]

[color=#ffff55]EXAMPLES[/color]
  [color=#00ff00]quit[/color]
  [color=#00ff00]exit[/color]

""",
# -------
"clear": """[color=#ffff55]CLEAR[/color]                                         [color=#888888]general[/color]

  [color=#00ff00]clear[/color]

[color=#ffff55]DESCRIPTION[/color]
  Clears all text currently displayed in the console output buffer.
  Does not affect command history or any game state.

[color=#ffff55]USAGE[/color]
  [color=#00ff00]clear[/color]

[color=#ffff55]SEE ALSO[/color]
  [color=#00ff00]delete history[/color]

""",
# -------
"delete_history": """[color=#ffff55]DELETE HISTORY[/color]                               [color=#888888]general[/color]

  [color=#00ff00]delete history[/color]

[color=#ffff55]DESCRIPTION[/color]
  Clears the persistent command history. The history file stored at
  [color=#888888]user://console_history.txt[/color] is deleted and the in-memory history
  list is reset. Up/Down navigation will be empty after this command.

[color=#ffff55]USAGE[/color]
  [color=#00ff00]delete history[/color]

[color=#ffff55]SEE ALSO[/color]
  [color=#00ff00]clear[/color]

""",
# -------
"help": """[color=#ffff55]HELP[/color]                                          [color=#888888]general[/color]

  [color=#00ff00]help[/color] [color=#666666][command][/color]

[color=#ffff55]DESCRIPTION[/color]
  With no arguments, displays a summary of all built-in commands and
  key bindings. When a command name is given, displays a detailed
  reference page for that specific command.

[color=#ffff55]USAGE[/color]
  [color=#00ff00]help[/color]
  [color=#00ff00]help[/color] [color=#666666][command][/color]

[color=#ffff55]ARGUMENTS[/color]
  [color=#666666][command][/color]   Name of any registered command (optional).
             Spaces and underscores are both accepted.

[color=#ffff55]EXAMPLES[/color]
  [color=#00ff00]help[/color]
  [color=#00ff00]help[/color] calc
  [color=#00ff00]help[/color] load scene
  [color=#00ff00]help[/color] vsync

[color=#ffff55]SEE ALSO[/color]
  [color=#00ff00]commands[/color]  [color=#00ff00]commands list[/color]

""",
# -------
"commands": """[color=#ffff55]COMMANDS[/color]                                      [color=#888888]general[/color]

  [color=#00ff00]commands[/color]

[color=#ffff55]DESCRIPTION[/color]
  Prints a compact list of every visible command name. Hidden commands
  (registered with [color=#888888]add_hidden_command[/color]) are excluded. Use
  [color=#00ff00]commands list[/color] to also see argument signatures and descriptions.

[color=#ffff55]USAGE[/color]
  [color=#00ff00]commands[/color]

[color=#ffff55]SEE ALSO[/color]
  [color=#00ff00]commands list[/color]  [color=#00ff00]help[/color]

""",
# -------
"commands_list": """[color=#ffff55]COMMANDS LIST[/color]                                [color=#888888]general[/color]

  [color=#00ff00]commands list[/color]

[color=#ffff55]DESCRIPTION[/color]
  Prints all visible commands with their full argument signatures and
  one-line descriptions. Required arguments are shown in
  [color=#5555ff]<angle brackets>[/color] and optional ones in [color=#666666][square brackets][/color].

[color=#ffff55]USAGE[/color]
  [color=#00ff00]commands list[/color]

[color=#ffff55]SEE ALSO[/color]
  [color=#00ff00]commands[/color]  [color=#00ff00]help[/color]

""",
# ---- Output ----
"echo": """[color=#ffff55]ECHO[/color]                                          [color=#888888]output[/color]

  [color=#00ff00]echo[/color] [color=#5555ff]<string>[/color]
  [color=#00ff00]echo warning[/color] [color=#5555ff]<string>[/color]
  [color=#00ff00]echo info[/color] [color=#5555ff]<string>[/color]
  [color=#00ff00]echo error[/color] [color=#5555ff]<string>[/color]

[color=#ffff55]DESCRIPTION[/color]
  Prints a message to the console output. The four variants apply
  different color styling:
    [color=#00ff00]echo[/color]          — plain white text
    [color=#ffff55]echo warning[/color]  — yellow warning text
    [color=#5555ff]echo info[/color]     — blue info text
    [color=#ff4444]echo error[/color]    — red error text

  The entire remainder of the line (including spaces) is treated as
  the string argument, so quotes are not required.

[color=#ffff55]USAGE[/color]
  [color=#00ff00]echo[/color] [color=#5555ff]<string>[/color]
  [color=#00ff00]echo warning[/color] [color=#5555ff]<string>[/color]
  [color=#00ff00]echo info[/color] [color=#5555ff]<string>[/color]
  [color=#00ff00]echo error[/color] [color=#5555ff]<string>[/color]

[color=#ffff55]ARGUMENTS[/color]
  [color=#5555ff]<string>[/color]   Any text to display. Spaces are preserved.

[color=#ffff55]EXAMPLES[/color]
  [color=#00ff00]echo[/color] Hello, world!
  [color=#00ff00]echo warning[/color] Low memory detected
  [color=#00ff00]echo error[/color] Failed to load asset

""",
# ---- Utility ----
"calc": """[color=#ffff55]CALC[/color]                                          [color=#888888]utility[/color]

  [color=#00ff00]calc[/color] [color=#5555ff]<expression>[/color]

[color=#ffff55]DESCRIPTION[/color]
  Evaluates a mathematical expression using Godot's built-in
  [color=#888888]Expression[/color] class and prints the result. Supports standard
  arithmetic operators, parentheses, and most GDScript math functions
  (sin, cos, sqrt, pow, abs, floor, ceil, round, etc.).

[color=#ffff55]USAGE[/color]
  [color=#00ff00]calc[/color] [color=#5555ff]<expression>[/color]

[color=#ffff55]ARGUMENTS[/color]
  [color=#5555ff]<expression>[/color]   A mathematical expression. The entire remainder of the
               line is treated as one expression — no quotes needed.

[color=#ffff55]EXAMPLES[/color]
  [color=#00ff00]calc[/color] 2 + 2
  [color=#00ff00]calc[/color] sqrt(144)
  [color=#00ff00]calc[/color] sin(PI / 6)
  [color=#00ff00]calc[/color] (1920 * 1080) / 1000000.0
  [color=#00ff00]calc[/color] pow(2, 10)

[color=#ffff55]NOTES[/color]
  Division by zero and parse errors are reported as red error messages.

""",
# -------
"exec": """[color=#ffff55]EXEC[/color]                                          [color=#888888]utility[/color]

  [color=#00ff00]exec[/color] [color=#5555ff]<filename>[/color]

[color=#ffff55]DESCRIPTION[/color]
  Reads a plain-text file from [color=#888888]user://[/color] and executes each line as if
  it were typed into the console. Useful for running batches of
  commands or pre-defined debug scenarios.

[color=#ffff55]USAGE[/color]
  [color=#00ff00]exec[/color] [color=#5555ff]<filename>[/color]

[color=#ffff55]ARGUMENTS[/color]
  [color=#5555ff]<filename>[/color]   Name of the script file without extension. The file must
              exist at [color=#888888]user://<filename>.txt[/color].

[color=#ffff55]EXAMPLES[/color]
  [color=#00ff00]exec[/color] setup
  [color=#00ff00]exec[/color] benchmark

[color=#ffff55]NOTES[/color]
  The [color=#888888]user://[/color] directory is platform-specific. On Linux it is typically
  [color=#888888]~/.local/share/<project_name>/[/color].
  Blank lines and unrecognised commands are silently skipped.

""",
# ---- Display ----
"console_full": """[color=#ffff55]CONSOLE POSITION[/color]                             [color=#888888]display[/color]

  [color=#00ff00]console full[/color]
  [color=#00ff00]console bottom[/color]
  [color=#00ff00]console top[/color]
  [color=#00ff00]console left[/color]
  [color=#00ff00]console right[/color]
  [color=#00ff00]console upper_left[/color]
  [color=#00ff00]console upper_right[/color]
  [color=#00ff00]console lower_left[/color]
  [color=#00ff00]console lower_right[/color]

[color=#ffff55]DESCRIPTION[/color]
  Repositions and resizes the console overlay to one of nine preset
  layouts. The change takes effect immediately.

    [color=#00ff00]console full[/color]         Covers the entire game window
    [color=#00ff00]console bottom[/color]       Occupies the bottom half
    [color=#00ff00]console top[/color]          Occupies the top half
    [color=#00ff00]console left[/color]         Occupies the left half
    [color=#00ff00]console right[/color]        Occupies the right half
    [color=#00ff00]console upper_left[/color]   Occupies the upper left corner
    [color=#00ff00]console upper_right[/color]  Occupies the upper right corner
    [color=#00ff00]console lower_left[/color]   Occupies the lower left corner
    [color=#00ff00]console lower_right[/color]  Occupies the lower right corner

  The position can also be cycled at runtime with [color=#5555ff]Ctrl+~[/color].

[color=#ffff55]USAGE[/color]
  [color=#00ff00]console full[/color]
  [color=#00ff00]console bottom[/color]
  [color=#00ff00]console top[/color]
  [color=#00ff00]console left[/color]
  [color=#00ff00]console right[/color]
  [color=#00ff00]console upper_left[/color]
  [color=#00ff00]console upper_right[/color]
  [color=#00ff00]console lower_left[/color]
  [color=#00ff00]console lower_right[/color]

[color=#ffff55]SEE ALSO[/color]
  [color=#00ff00]transparency[/color]

""",
# -------
"transparency": """[color=#ffff55]TRANSPARENCY[/color]                                 [color=#888888]display[/color]

  [color=#00ff00]transparency[/color] [color=#5555ff]<level>[/color]

[color=#ffff55]DESCRIPTION[/color]
  Sets the opacity of the console background panel.
  [color=#888888]0[/color] makes the background fully opaque; [color=#888888]100[/color] makes it completely
  invisible (the text remains readable either way).

[color=#ffff55]USAGE[/color]
  [color=#00ff00]transparency[/color] [color=#5555ff]<level>[/color]

[color=#ffff55]ARGUMENTS[/color]
  [color=#5555ff]<level>[/color]   Integer or float from [color=#888888]0[/color] (opaque) to [color=#888888]100[/color] (invisible).
            Values outside this range are clamped automatically.

[color=#ffff55]EXAMPLES[/color]
  [color=#00ff00]transparency[/color] 0
  [color=#00ff00]transparency[/color] 50
  [color=#00ff00]transparency[/color] 85

[color=#ffff55]SEE ALSO[/color]
  [color=#00ff00]console full[/color]

""",
# ---- Time ----
"timescale": """[color=#ffff55]TIMESCALE[/color]                                    [color=#888888]time[/color]

  [color=#00ff00]timescale[/color] [color=#5555ff]<speed>[/color]

[color=#ffff55]DESCRIPTION[/color]
  Sets [color=#888888]Engine.time_scale[/color], which scales the speed of physics,
  animations, and all [color=#888888]_process[/color] / [color=#888888]_physics_process[/color] delta values.
  A value of [color=#888888]1.0[/color] is normal speed.

[color=#ffff55]USAGE[/color]
  [color=#00ff00]timescale[/color] [color=#5555ff]<speed>[/color]

[color=#ffff55]ARGUMENTS[/color]
  [color=#5555ff]<speed>[/color]   Positive float. [color=#888888]0.5[/color] = half speed, [color=#888888]2.0[/color] = double speed.
            Minimum is [color=#888888]0.0[/color] (frozen time). There is no maximum.

[color=#ffff55]EXAMPLES[/color]
  [color=#00ff00]timescale[/color] 1.0
  [color=#00ff00]timescale[/color] 0.5
  [color=#00ff00]timescale[/color] 2.0
  [color=#00ff00]timescale[/color] 0.0

[color=#ffff55]NOTES[/color]
  This affects the entire engine. Input processing and the console
  itself are not slowed down.

[color=#ffff55]SEE ALSO[/color]
  [color=#00ff00]pause[/color]  [color=#00ff00]physics toggle[/color]

""",
# ---- Scene ----
"pause": """[color=#ffff55]PAUSE / UNPAUSE[/color]                              [color=#888888]scene[/color]

  [color=#00ff00]pause[/color]
  [color=#00ff00]unpause[/color]

[color=#ffff55]DESCRIPTION[/color]
  Sets [color=#888888]SceneTree.paused[/color]. When paused, all nodes that do not have
  their process mode set to [color=#888888]PROCESS_MODE_ALWAYS[/color] stop executing
  [color=#888888]_process[/color] and [color=#888888]_physics_process[/color]. The console itself remains
  interactive while the game is paused.

[color=#ffff55]USAGE[/color]
  [color=#00ff00]pause[/color]
  [color=#00ff00]unpause[/color]

[color=#ffff55]SEE ALSO[/color]
  [color=#00ff00]timescale[/color]  [color=#00ff00]physics toggle[/color]

""",
# -------
"restart": """[color=#ffff55]RESTART[/color]                                      [color=#888888]scene[/color]

  [color=#00ff00]restart[/color]  [color=#888888]alias:[/color] [color=#00ff00]reload[/color]

[color=#ffff55]DESCRIPTION[/color]
  Calls [color=#888888]SceneTree.reload_current_scene()[/color], which tears down the
  current scene and reloads it from disk. All runtime state is lost.

[color=#ffff55]USAGE[/color]
  [color=#00ff00]restart[/color]
  [color=#00ff00]reload[/color]

[color=#ffff55]SEE ALSO[/color]
  [color=#00ff00]load scene[/color]  [color=#00ff00]scene info[/color]

""",
# -------
"load_scene": """[color=#ffff55]LOAD SCENE[/color]                                   [color=#888888]scene[/color]

  [color=#00ff00]load scene[/color] [color=#5555ff]<scene_path>[/color]

[color=#ffff55]DESCRIPTION[/color]
  Transitions to a different scene using
  [color=#888888]SceneTree.change_scene_to_file()[/color]. The current scene is freed
  and the target scene is loaded in its place.

[color=#ffff55]USAGE[/color]
  [color=#00ff00]load scene[/color] [color=#5555ff]<scene_path>[/color]

[color=#ffff55]ARGUMENTS[/color]
  [color=#5555ff]<scene_path>[/color]   Path to a [color=#888888].tscn[/color] file. Accepts any of:
                 • Full path:  [color=#888888]res://levels/world.tscn[/color]
                 • No prefix:  [color=#888888]levels/world[/color]  (res:// is prepended)
                 • No ext:     [color=#888888]res://levels/world[/color]  (.tscn appended)

[color=#ffff55]EXAMPLES[/color]
  [color=#00ff00]load scene[/color] res://main.tscn
  [color=#00ff00]load scene[/color] levels/dungeon
  [color=#00ff00]load scene[/color] main

[color=#ffff55]SEE ALSO[/color]
  [color=#00ff00]list scenes[/color]  [color=#00ff00]restart[/color]  [color=#00ff00]scene info[/color]

""",
# -------
"list_scenes": """[color=#ffff55]LIST SCENES[/color]                                  [color=#888888]scene[/color]

  [color=#00ff00]list scenes[/color]

[color=#ffff55]DESCRIPTION[/color]
  Recursively scans the [color=#888888]res://[/color] directory (excluding [color=#888888]addons/[/color]) and
  prints the path of every [color=#888888].tscn[/color] file found.

[color=#ffff55]USAGE[/color]
  [color=#00ff00]list scenes[/color]

[color=#ffff55]SEE ALSO[/color]
  [color=#00ff00]load scene[/color]  [color=#00ff00]scene info[/color]

""",
# -------
"list_scripts": """[color=#ffff55]LIST SCRIPTS[/color]                                 [color=#888888]utility[/color]

  [color=#00ff00]list scripts[/color]

[color=#ffff55]DESCRIPTION[/color]
  Lists all [color=#888888].txt[/color] script files stored in the [color=#888888]user://[/color] directory
  that can be executed with the [color=#00ff00]exec[/color] command.

[color=#ffff55]USAGE[/color]
  [color=#00ff00]list scripts[/color]

[color=#ffff55]SEE ALSO[/color]
  [color=#00ff00]exec[/color]

""",
# -------
"scene_info": """[color=#ffff55]SCENE INFO[/color]                                   [color=#888888]scene[/color]

  [color=#00ff00]scene info[/color]

[color=#ffff55]DESCRIPTION[/color]
  Displays metadata about the currently active scene: its name,
  [color=#888888]res://[/color] path, root node type, and total node count.

[color=#ffff55]USAGE[/color]
  [color=#00ff00]scene info[/color]

[color=#ffff55]SEE ALSO[/color]
  [color=#00ff00]print tree[/color]  [color=#00ff00]list scenes[/color]  [color=#00ff00]restart[/color]

""",
# ---- Inspection ----
"print_tree": """[color=#ffff55]PRINT TREE[/color]                                   [color=#888888]inspection[/color]

  [color=#00ff00]print tree[/color]

[color=#ffff55]DESCRIPTION[/color]
  Recursively prints every node in the current scene tree, indented
  to reflect nesting depth. Each entry shows the node name, class,
  and (when applicable) its [color=#888888].tscn[/color] path for instanced sub-scenes.

[color=#ffff55]USAGE[/color]
  [color=#00ff00]print tree[/color]

[color=#ffff55]SEE ALSO[/color]
  [color=#00ff00]print node[/color]  [color=#00ff00]scene info[/color]

""",
# -------
"print_node": """[color=#ffff55]PRINT NODE[/color]                                   [color=#888888]inspection[/color]

  [color=#00ff00]print node[/color] [color=#5555ff]<node_path>[/color]

[color=#ffff55]DESCRIPTION[/color]
  Prints detailed information about a specific node: its path,
  owner, child count, scene file, position (for Node2D/Node3D),
  attached script, and all script-level exported variables.

[color=#ffff55]USAGE[/color]
  [color=#00ff00]print node[/color] [color=#5555ff]<node_path>[/color]

[color=#ffff55]ARGUMENTS[/color]
  [color=#5555ff]<node_path>[/color]   A NodePath relative to the current scene root, or an
               absolute path from [color=#888888]/root[/color].

[color=#ffff55]EXAMPLES[/color]
  [color=#00ff00]print node[/color] Player
  [color=#00ff00]print node[/color] Player/Sprite2D
  [color=#00ff00]print node[/color] /root/Main/HUD

[color=#ffff55]SEE ALSO[/color]
  [color=#00ff00]print tree[/color]  [color=#00ff00]list autoloads[/color]

""",
# -------
"list_autoloads": """[color=#ffff55]LIST AUTOLOADS[/color]                               [color=#888888]inspection[/color]

  [color=#00ff00]list autoloads[/color]

[color=#ffff55]DESCRIPTION[/color]
  Lists every autoload singleton registered in the project. For each
  entry the console shows the node name, its Godot class, and the
  path to its attached script.

[color=#ffff55]USAGE[/color]
  [color=#00ff00]list autoloads[/color]

[color=#ffff55]SEE ALSO[/color]
  [color=#00ff00]print node[/color]  [color=#00ff00]engine info[/color]

""",
# -------
"engine_info": """[color=#ffff55]ENGINE INFO[/color]                                  [color=#888888]inspection[/color]

  [color=#00ff00]engine info[/color]

[color=#ffff55]DESCRIPTION[/color]
  Displays information about the running Godot engine and project:
  • Godot version and status string
  • Project name and version (from ProjectSettings)
  • Rendering method
  • GPU adapter name
  • Host OS name and version
  • Whether this is a debug build

[color=#ffff55]USAGE[/color]
  [color=#00ff00]engine info[/color]

[color=#ffff55]SEE ALSO[/color]
  [color=#00ff00]fps[/color]  [color=#00ff00]mem[/color]  [color=#00ff00]vsync[/color]

""",
# ---- Performance ----
"fps": """[color=#ffff55]FPS[/color]                                           [color=#888888]performance[/color]

  [color=#00ff00]fps[/color]

[color=#ffff55]DESCRIPTION[/color]
  Prints a one-line snapshot of the current frames-per-second and
  the corresponding frame time in milliseconds, sampled at the moment
  the command is executed.

[color=#ffff55]USAGE[/color]
  [color=#00ff00]fps[/color]

[color=#ffff55]NOTES[/color]
  This is a point-in-time reading. For continuous monitoring consider
  Godot's built-in [color=#888888]Profiler[/color] or the [color=#888888]Performance[/color] singleton.

[color=#ffff55]SEE ALSO[/color]
  [color=#00ff00]mem[/color]  [color=#00ff00]engine info[/color]  [color=#00ff00]vsync[/color]

""",
# -------
"mem": """[color=#ffff55]MEM[/color]                                           [color=#888888]performance[/color]

  [color=#00ff00]mem[/color]

[color=#ffff55]DESCRIPTION[/color]
  Prints current static memory usage and the peak usage recorded
  since the process started. In debug builds additional counters are
  shown: total object count, node count, orphan node count, and
  resource count.

[color=#ffff55]USAGE[/color]
  [color=#00ff00]mem[/color]

[color=#ffff55]NOTES[/color]
  Object/node counters are only available in debug builds. They will
  not appear in exported release builds.

[color=#ffff55]SEE ALSO[/color]
  [color=#00ff00]fps[/color]  [color=#00ff00]engine info[/color]

""",
# -------
"vsync": """[color=#ffff55]VSYNC[/color]                                         [color=#888888]performance[/color]

  [color=#00ff00]vsync[/color] [color=#666666][mode][/color]

[color=#ffff55]DESCRIPTION[/color]
  Gets or sets the VSync mode for the main window.
  When called with no argument the current mode is printed.
  When called with a mode name the display server is updated
  immediately.

[color=#ffff55]USAGE[/color]
  [color=#00ff00]vsync[/color]
  [color=#00ff00]vsync[/color] [color=#666666][mode][/color]

[color=#ffff55]ARGUMENTS[/color]
  [color=#666666][mode][/color]   One of the following (case-insensitive):
          [color=#888888]disabled[/color]   — no synchronisation (may tear)
          [color=#888888]enabled[/color]    — standard VSync (cap to refresh rate)
          [color=#888888]adaptive[/color]   — VSync when above refresh rate, free otherwise
          [color=#888888]mailbox[/color]    — low-latency triple buffering

[color=#ffff55]EXAMPLES[/color]
  [color=#00ff00]vsync[/color]
  [color=#00ff00]vsync[/color] disabled
  [color=#00ff00]vsync[/color] adaptive

[color=#ffff55]SEE ALSO[/color]
  [color=#00ff00]fps[/color]  [color=#00ff00]engine info[/color]

""",
# -------
"physics_toggle": """[color=#ffff55]PHYSICS TOGGLE[/color]                               [color=#888888]performance[/color]

  [color=#00ff00]physics toggle[/color]

[color=#ffff55]DESCRIPTION[/color]
  Toggles physics processing for the entire current scene by setting
  the root node's [color=#888888]process_mode[/color] to [color=#888888]PROCESS_MODE_DISABLED[/color] or back
  to [color=#888888]PROCESS_MODE_INHERIT[/color]. Call again to re-enable.

[color=#ffff55]USAGE[/color]
  [color=#00ff00]physics toggle[/color]

[color=#ffff55]NOTES[/color]
  This affects the whole scene subtree. Nodes that explicitly set
  their own [color=#888888]process_mode[/color] will not be affected.

[color=#ffff55]SEE ALSO[/color]
  [color=#00ff00]pause[/color]  [color=#00ff00]timescale[/color]

""",
# ---- Audio ----
"mute": """[color=#ffff55]MUTE / UNMUTE[/color]                                [color=#888888]audio[/color]

  [color=#00ff00]mute[/color]
  [color=#00ff00]unmute[/color]

[color=#ffff55]DESCRIPTION[/color]
  Mutes or unmutes the [color=#888888]Master[/color] audio bus without changing its volume
  level, so [color=#00ff00]unmute[/color] restores the previous volume exactly.

[color=#ffff55]USAGE[/color]
  [color=#00ff00]mute[/color]
  [color=#00ff00]unmute[/color]

[color=#ffff55]SEE ALSO[/color]
  [color=#00ff00]volume[/color]  [color=#00ff00]list buses[/color]

""",
# -------
"volume": """[color=#ffff55]VOLUME[/color]                                        [color=#888888]audio[/color]

  [color=#00ff00]volume[/color] [color=#5555ff]<level>[/color]
  [color=#00ff00]volume up[/color]
  [color=#00ff00]volume down[/color]

[color=#ffff55]DESCRIPTION[/color]
  Sets the [color=#888888]Master[/color] bus volume.
    [color=#00ff00]volume[/color] [color=#5555ff]<level>[/color]  — set to an exact linear value (0.0 – 1.0)
    [color=#00ff00]volume up[/color]      — increase by 10 percentage points
    [color=#00ff00]volume down[/color]    — decrease by 10 percentage points

  Setting volume to [color=#888888]0.0[/color] also mutes the bus automatically.
  Setting it above [color=#888888]0.0[/color] unmutes it.

[color=#ffff55]USAGE[/color]
  [color=#00ff00]volume[/color] [color=#5555ff]<level>[/color]
  [color=#00ff00]volume up[/color]
  [color=#00ff00]volume down[/color]

[color=#ffff55]ARGUMENTS[/color]
  [color=#5555ff]<level>[/color]   Float from [color=#888888]0.0[/color] (silent) to [color=#888888]1.0[/color] (full). Values outside this
            range are clamped automatically.

[color=#ffff55]EXAMPLES[/color]
  [color=#00ff00]volume[/color] 1.0
  [color=#00ff00]volume[/color] 0.5
  [color=#00ff00]volume[/color] 0.0
  [color=#00ff00]volume up[/color]
  [color=#00ff00]volume down[/color]

[color=#ffff55]SEE ALSO[/color]
  [color=#00ff00]mute[/color]  [color=#00ff00]list buses[/color]

""",
# -------
"list_buses": """[color=#ffff55]LIST BUSES[/color]                                   [color=#888888]audio[/color]

  [color=#00ff00]list buses[/color]

[color=#ffff55]DESCRIPTION[/color]
  Lists every audio bus configured in the AudioServer, showing its
  name, current volume as a percentage, mute status, and send target
  (the bus it feeds into, if any).

[color=#ffff55]USAGE[/color]
  [color=#00ff00]list buses[/color]

[color=#ffff55]SEE ALSO[/color]
  [color=#00ff00]mute[/color]  [color=#00ff00]volume[/color]

""",
	}


# ---- Physics ----

var _physics_paused := false

func physics_toggle() -> void:
	_physics_paused = !_physics_paused
	if _physics_paused:
		console.get_tree().current_scene.process_mode = Node.PROCESS_MODE_DISABLED
		console.print_info("Physics processing disabled.")
	else:
		console.get_tree().current_scene.process_mode = Node.PROCESS_MODE_INHERIT
		console.print_info("Physics processing enabled.")
