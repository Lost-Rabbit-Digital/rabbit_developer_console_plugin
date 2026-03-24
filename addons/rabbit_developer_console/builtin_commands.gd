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
	console.add_command("help", help, 0, 0, "Displays instructions on how to use the console.")
	console.add_command("commands_list", commands_list, 0, 0, "Lists all commands and their descriptions.")
	console.add_command("commands", commands, 0, 0, "Lists commands with no descriptions.")

	# Output
	console.add_command("echo", console.print_line, ["string"], 1, "Prints given string to the console.")
	console.add_command("echo_warning", console.print_warning, ["string"], 1, "Prints given string as warning to the console.")
	console.add_command("echo_info", console.print_info, ["string"], 1, "Prints given string as info to the console.")
	console.add_command("echo_error", console.print_error, ["string"], 1, "Prints given string as an error to the console.")

	# Utility
	console.add_command("calc", calculate, ["mathematical expression to evaluate"], 0, "Evaluates the math passed in for quick arithmetic.")
	console.add_command("exec", exec, ["filename"], 1, "Execute a script.")

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


func clear() -> void:
	console.rich_label.clear()


func delete_history() -> void:
	console.console_history.clear()
	console.console_history_index = 0
	DirAccess.remove_absolute("user://console_history.txt")


func help() -> void:
	console.rich_label.append_text("[color=#ffff55]BUILT-IN COMMANDS[/color]

[color=#888888]  General[/color]
  [color=#00ff00]clear[/color]            Clear the terminal screen
  [color=#00ff00]commands[/color]         List available commands
  [color=#00ff00]commands_list[/color]    List commands with usage details
  [color=#00ff00]delete_history[/color]   Clear command history
  [color=#00ff00]help[/color]             Show this help message
  [color=#00ff00]quit[/color] / [color=#00ff00]exit[/color]     Terminate the application

[color=#888888]  Output[/color]
  [color=#00ff00]echo[/color]             Print a string to stdout
  [color=#00ff00]echo_error[/color]       Print a string to stderr
  [color=#00ff00]echo_info[/color]        Print an info message
  [color=#00ff00]echo_warning[/color]     Print a warning message

[color=#888888]  Utility[/color]
  [color=#00ff00]calc[/color]             Evaluate a mathematical expression
  [color=#00ff00]exec[/color]             Execute commands from a script file

[color=#888888]  Display[/color]
  [color=#00ff00]console_full[/color]     Set console to full window mode
  [color=#00ff00]console_bottom[/color]   Dock console to bottom half
  [color=#00ff00]console_top[/color]      Dock console to top half
  [color=#00ff00]console_left[/color]     Dock console to left half
  [color=#00ff00]console_right[/color]    Dock console to right half
  [color=#00ff00]transparency[/color]     Set background transparency (0-100)

[color=#888888]  Time[/color]
  [color=#00ff00]timescale[/color]        Set Engine.time_scale (e.g. 0.5, 2.0)

[color=#888888]  Scene[/color]
  [color=#00ff00]pause[/color] / [color=#00ff00]unpause[/color]  Toggle node processing
  [color=#00ff00]restart[/color] / [color=#00ff00]reload[/color] Restart the current scene
  [color=#00ff00]load_scene[/color]       Change to a scene by path or name
  [color=#00ff00]list_scenes[/color]      List all .tscn files in the project
  [color=#00ff00]scene_info[/color]       Info about the current scene

[color=#888888]  Inspection[/color]
  [color=#00ff00]print_tree[/color]       Print the current scene tree
  [color=#00ff00]print_node[/color]       Print details about a node at a path
  [color=#00ff00]list_autoloads[/color]   List all autoload singletons
  [color=#00ff00]engine_info[/color]      Godot version, renderer, adapter info

[color=#888888]  Performance[/color]
  [color=#00ff00]fps[/color]              Show FPS and frame time
  [color=#00ff00]mem[/color]              Show memory usage
  [color=#00ff00]vsync[/color]            Get or set VSync mode
  [color=#00ff00]physics_toggle[/color]   Toggle physics processing on/off

[color=#888888]  Audio[/color]
  [color=#00ff00]mute[/color] / [color=#00ff00]unmute[/color]   Toggle game audio
  [color=#00ff00]volume[/color]           Set master volume (0.0-1.0)
  [color=#00ff00]volume_up[/color] / [color=#00ff00]down[/color] Adjust volume by 10%%
  [color=#00ff00]list_buses[/color]       List all audio buses

[color=#ffff55]KEY BINDINGS[/color]
  [color=#5555ff]Up/Down[/color]           Navigate command history
  [color=#5555ff]PageUp/PageDown[/color]   Scroll output buffer
  [color=#5555ff]Tab[/color]              Auto-complete; press again to cycle
  [color=#5555ff]Ctrl+~[/color]           Cycle console position
  [color=#5555ff]Ctrl+Scroll[/color]      Adjust font size
  [color=#5555ff]~ / Esc[/color]          Close console
")


func commands() -> void:
	var cmds := []
	for command in console.console_commands:
		if (!console.console_commands[command].hidden):
			cmds.append(command.replace("_", " "))
	cmds.sort()
	var line := ""
	for i in range(cmds.size()):
		line += "[color=#00ff00]%s[/color]" % cmds[i]
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
		var command_display := command.replace("_", " ")
		var arguments_string := ""
		var description : String = console.console_commands[command].description
		for i in range(console.console_commands[command].arguments.size()):
			if i < console.console_commands[command].required:
				arguments_string += " [color=#5555ff]<" + console.console_commands[command].arguments[i] + ">[/color]"
			else:
				arguments_string += " [color=#666666][" + console.console_commands[command].arguments[i] + "][/color]"
		console.rich_label.append_text("  [color=#00ff00]%-18s[/color]%s  [color=#888888]%s[/color]\n" % [command_display, arguments_string, description])
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
	var name_str := "[color=#00ff00]%s[/color] [color=%s](%s)[/color]" % [node.name, type_color, node.get_class()]
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
