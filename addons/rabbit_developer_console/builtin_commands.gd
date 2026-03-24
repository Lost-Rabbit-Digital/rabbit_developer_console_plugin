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
	console.add_command("exec", exec, 1, 1, "Execute a script.")

	# Scene management
	console.add_command("pause", pause, 0, 0, "Pauses node processing.")
	console.add_command("unpause", unpause, 0, 0, "Unpauses node processing.")
	console.add_command("restart", restart_scene, 0, 0, "Restarts the current scene.")
	console.add_command("reload", restart_scene, 0, 0, "Restarts the current scene.")

	# Audio
	console.add_command("mute", mute, 0, 0, "Mutes all game audio.")
	console.add_command("unmute", unmute, 0, 0, "Unmutes all game audio.")
	console.add_command("volume", set_volume, ["level 0.0-1.0"], 1, "Sets master volume (0.0 to 1.0).")
	console.add_command("volume_up", volume_up, 0, 0, "Increases master volume by 10%.")
	console.add_command("volume_down", volume_down, 0, 0, "Decreases master volume by 10%.")


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
  [color=#00ff00]calc[/color]             Evaluate a mathematical expression
  [color=#00ff00]clear[/color]            Clear the terminal screen
  [color=#00ff00]commands[/color]         List available commands
  [color=#00ff00]commands_list[/color]    List commands with usage details
  [color=#00ff00]delete_history[/color]   Clear command history
  [color=#00ff00]echo[/color]             Print a string to stdout
  [color=#00ff00]echo_error[/color]       Print a string to stderr
  [color=#00ff00]echo_info[/color]        Print an info message
  [color=#00ff00]echo_warning[/color]     Print a warning message
  [color=#00ff00]exec[/color]             Execute commands from a script file
  [color=#00ff00]mute[/color] / [color=#00ff00]unmute[/color]   Toggle game audio
  [color=#00ff00]pause[/color]            Pause node processing
  [color=#00ff00]restart[/color] / [color=#00ff00]reload[/color] Restart the current scene
  [color=#00ff00]unpause[/color]          Resume node processing
  [color=#00ff00]volume[/color]           Set master volume (0.0-1.0)
  [color=#00ff00]volume_up[/color]        Increase volume by 10%%
  [color=#00ff00]volume_down[/color]      Decrease volume by 10%%
  [color=#00ff00]quit[/color] / [color=#00ff00]exit[/color]     Terminate the application

[color=#ffff55]KEY BINDINGS[/color]
  [color=#5555ff]Up/Down[/color]           Navigate command history
  [color=#5555ff]PageUp/PageDown[/color]   Scroll output buffer
  [color=#5555ff]Tab[/color]              Auto-complete; press again to cycle
  [color=#5555ff]Ctrl+~[/color]           Toggle fullscreen/half-screen
  [color=#5555ff]Ctrl+Scroll[/color]      Adjust font size
  [color=#5555ff]~ / Esc[/color]          Close console
")


func commands() -> void:
	var cmds := []
	for command in console.console_commands:
		if (!console.console_commands[command].hidden):
			cmds.append(str(command))
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
		var arguments_string := ""
		var description : String = console.console_commands[command].description
		for i in range(console.console_commands[command].arguments.size()):
			if i < console.console_commands[command].required:
				arguments_string += " [color=#5555ff]<" + console.console_commands[command].arguments[i] + ">[/color]"
			else:
				arguments_string += " [color=#666666][" + console.console_commands[command].arguments[i] + "][/color]"
		console.rich_label.append_text("  [color=#00ff00]%-18s[/color]%s  [color=#888888]%s[/color]\n" % [command, arguments_string, description])
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
