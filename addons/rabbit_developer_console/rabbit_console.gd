extends Node

var enabled := true
var enable_on_release_build := false : set = set_enable_on_release_build
var pause_enabled := false
var font_size := -1:
	set(value):
		font_size = value
		_update_font_size()

signal console_opened
signal console_closed
signal console_unknown_command


class ConsoleCommand:
	var function : Callable
	var arguments : PackedStringArray
	var required : int
	var description : String
	var hidden : bool
	func _init(in_function : Callable, in_arguments : PackedStringArray, in_required : int = 0, in_description : String = ""):
		function = in_function
		arguments = in_arguments
		required = in_required
		description = in_description

var theme : Theme
var control := Control.new()

# If you want to customize the way the console looks, you can direcly modify
# the properties of the rich text and line edit here:
var rich_label := RichTextLabel.new()
var panel := Panel.new()
var line_edit := LineEdit.new()

var console_commands := {}
var command_parameters := {}
var console_history := []
var console_history_index := 0
var was_paused_already := false
var _builtin_commands : RefCounted

## Usage: Console.add_command("command_name", <function to call>, <number of arguments or array of argument names>, <required number of arguments>, "Help description")
func add_command(command_name : String, function : Callable, arguments = [], required: int = 0, description : String = "") -> void:
	if (arguments is int):
		# Legacy call using an argument number
		var param_array : PackedStringArray
		for i in range(arguments):
			param_array.append("arg_" + str(i + 1))
		console_commands[command_name] = ConsoleCommand.new(function, param_array, required, description)
	elif (arguments is Array):
		# New array argument system
		var str_args : PackedStringArray
		for argument in arguments:
			str_args.append(str(argument))
		console_commands[command_name] = ConsoleCommand.new(function, str_args, required, description)


## Adds a secret command that will not show up in the help or auto-complete.
func add_hidden_command(command_name : String, function : Callable, arguments = [], required : int = 0) -> void:
	add_command(command_name, function, arguments, required)
	console_commands[command_name].hidden = true


## Removes a command from the console.  This should be called on a script's _exit_tree()
## if you have console commands for things that are unloaded before the project closes.
func remove_command(command_name : String) -> void:
	console_commands.erase(command_name)
	command_parameters.erase(command_name)


## Useful if you have a list of possible parameters (ex: level names).
func add_command_autocomplete_list(command_name : String, param_list : PackedStringArray):
	command_parameters[command_name] = param_list


func _enter_tree() -> void:
	var console_history_file := FileAccess.open("user://console_history.txt", FileAccess.READ)
	if (console_history_file):
		while (!console_history_file.eof_reached()):
			var line := console_history_file.get_line()
			if (line.length()):
				add_input_history(line)

	if ProjectSettings.has_setting(&"console/theme"):
		theme = load(ProjectSettings.get_setting(&"console/theme"))
		if theme:
			control.theme = theme

	var canvas_layer := CanvasLayer.new()
	canvas_layer.layer = 3
	add_child(canvas_layer)
	control.anchor_bottom = 1.0
	control.anchor_right = 1.0
	canvas_layer.add_child(control)
	control.add_child(panel)
	panel.anchor_right = 1.0
	panel.anchor_bottom = 0.5

	# Terminal-style dark background for the panel
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.07, 0.07, 0.07, 0.95)
	panel_style.border_color = Color(0.2, 0.2, 0.2, 1.0)
	panel_style.set_border_width_all(1)
	panel.add_theme_stylebox_override("panel", panel_style)

	rich_label.selection_enabled = true
	rich_label.context_menu_enabled = true
	rich_label.bbcode_enabled = true
	rich_label.scroll_following = true
	rich_label.anchor_right = 1.0
	rich_label.anchor_bottom = 1.0
	rich_label.add_theme_color_override("default_color", Color(0.8, 0.8, 0.8, 1.0))
	rich_label.add_theme_color_override("font_selected_color", Color(1.0, 1.0, 1.0, 1.0))
	rich_label.add_theme_color_override("selection_color", Color(0.2, 0.4, 0.7, 0.5))
	if font_size > 0:
		rich_label.add_theme_font_size_override("normal_font_size", font_size)
		rich_label.add_theme_font_size_override("bold_font_size", font_size)
		rich_label.add_theme_font_size_override("bold_italics_font_size", font_size)
		rich_label.add_theme_font_size_override("italics_font_size", font_size)
		rich_label.add_theme_font_size_override("mono_font_size", font_size)
	panel.add_child(rich_label)
	_print_motd()
	line_edit.anchor_top = 0.5
	line_edit.anchor_right = 1.0
	line_edit.anchor_bottom = 0.5
	line_edit.placeholder_text = "Type 'help' for a list of commands"

	# Terminal-style input field
	var line_edit_style := StyleBoxFlat.new()
	line_edit_style.bg_color = Color(0.05, 0.05, 0.05, 0.95)
	line_edit_style.border_color = Color(0.2, 0.2, 0.2, 1.0)
	line_edit_style.set_border_width_all(1)
	line_edit_style.content_margin_left = 8
	line_edit.add_theme_stylebox_override("normal", line_edit_style)
	line_edit.add_theme_stylebox_override("focus", line_edit_style)
	line_edit.add_theme_color_override("font_color", Color(0.0, 1.0, 0.0, 1.0))
	line_edit.add_theme_color_override("font_placeholder_color", Color(0.4, 0.4, 0.4, 1.0))
	line_edit.add_theme_color_override("caret_color", Color(0.0, 1.0, 0.0, 1.0))

	if font_size > 0:
		line_edit.add_theme_font_size_override("font_size", font_size)
	control.add_child(line_edit)
	line_edit.text_submitted.connect(_on_text_entered)
	line_edit.text_changed.connect(_on_line_edit_text_changed)
	control.visible = false
	process_mode = PROCESS_MODE_ALWAYS


func _get_hostname() -> String:
	return ProjectSettings.get_setting("application/config/name", "localhost")


func _get_prompt() -> String:
	return "[color=#00ff00]user@%s[/color][color=#cccccc]:[/color][color=#5c5cff]~[/color][color=#cccccc]$[/color]" % _get_hostname()


func _print_motd() -> void:
	var hostname := _get_hostname()
	rich_label.append_text("[color=#00ff00]%s login: user[/color]\n" % hostname)
	rich_label.append_text("[color=#cccccc]Welcome to %s console v%s[/color]\n" % [hostname, "1.4.0"])
	rich_label.append_text("[color=#666666] * Documentation:  Type 'help' for built-in commands[/color]\n")
	rich_label.append_text("[color=#666666] * Command list:   Type 'commands' or 'commands_list'[/color]\n")
	rich_label.append_text("[color=#666666]Last login: %s on tty1[/color]\n\n" % Time.get_datetime_string_from_system())


func _update_font_size():
	if font_size > 0:
		line_edit.add_theme_font_size_override("font_size", font_size)
		rich_label.add_theme_font_size_override("normal_font_size", font_size)
		rich_label.add_theme_font_size_override("bold_font_size", font_size)
		rich_label.add_theme_font_size_override("bold_italics_font_size", font_size)
		rich_label.add_theme_font_size_override("italics_font_size", font_size)
		rich_label.add_theme_font_size_override("mono_font_size", font_size)
	else:
		line_edit.remove_theme_font_size_override("font_size")
		rich_label.remove_theme_font_size_override("normal_font_size")
		rich_label.remove_theme_font_size_override("bold_font_size")
		rich_label.remove_theme_font_size_override("bold_italics_font_size")
		rich_label.remove_theme_font_size_override("italics_font_size")
		rich_label.remove_theme_font_size_override("mono_font_size")


func _exit_tree() -> void:
	var console_history_file := FileAccess.open("user://console_history.txt", FileAccess.WRITE)
	if (console_history_file):
		var write_index := 0
		var start_write_index := console_history.size() - 100 # Max lines to write
		for line in console_history:
			if (write_index >= start_write_index):
				console_history_file.store_line(line)
			write_index += 1


func _ready() -> void:
	var BuiltinCommands := load("res://addons/rabbit_developer_console/builtin_commands.gd")
	_builtin_commands = BuiltinCommands.new(self)
	_builtin_commands.register_all()


func _input(event : InputEvent) -> void:
	if (event is InputEventKey):
		if (event.get_physical_keycode_with_modifiers() == KEY_QUOTELEFT): # ~ key.
			if (event.pressed):
				toggle_console()
			get_tree().get_root().set_input_as_handled()
		elif (event.physical_keycode == KEY_QUOTELEFT and event.is_command_or_control_pressed()): # Toggles console size or opens big console.
			if (event.pressed):
				if (control.visible):
					toggle_size()
				else:
					toggle_console()
					toggle_size()
			get_tree().get_root().set_input_as_handled()
		elif (event.get_physical_keycode_with_modifiers() == KEY_ESCAPE && control.visible): # Disable console on ESC
			if (event.pressed):
				toggle_console()
				get_tree().get_root().set_input_as_handled()
		if (control.visible and event.pressed):
			if (event.get_physical_keycode_with_modifiers() == KEY_UP):
				get_tree().get_root().set_input_as_handled()
				if (console_history_index > 0):
					console_history_index -= 1
					if (console_history_index >= 0):
						line_edit.text = console_history[console_history_index]
						line_edit.caret_column = line_edit.text.length()
						reset_autocomplete()
			if (event.get_physical_keycode_with_modifiers() == KEY_DOWN):
				get_tree().get_root().set_input_as_handled()
				if (console_history_index < console_history.size()):
					console_history_index += 1
					if (console_history_index < console_history.size()):
						line_edit.text = console_history[console_history_index]
						line_edit.caret_column = line_edit.text.length()
						reset_autocomplete()
					else:
						line_edit.text = ""
						reset_autocomplete()
			if (event.get_physical_keycode_with_modifiers() == KEY_PAGEUP):
				var scroll := rich_label.get_v_scroll_bar()
				var tween := create_tween()
				tween.tween_property(scroll, "value",  scroll.value - (scroll.page - scroll.page * 0.1), 0.1)
				get_tree().get_root().set_input_as_handled()
			if (event.get_physical_keycode_with_modifiers() == KEY_PAGEDOWN):
				var scroll := rich_label.get_v_scroll_bar()
				var tween := create_tween()
				tween.tween_property(scroll, "value",  scroll.value + (scroll.page - scroll.page * 0.1), 0.1)
				get_tree().get_root().set_input_as_handled()
			if (event.get_physical_keycode_with_modifiers() == KEY_TAB):
				autocomplete()
				get_tree().get_root().set_input_as_handled()
	elif event is InputEventMouseButton:
				if (control.visible):
					if (event.is_command_or_control_pressed()):
						if event.button_index == MOUSE_BUTTON_WHEEL_UP: # Increase font size with ctrl+mouse wheel up
							if font_size <= 0:
								font_size = 16 # Use default font size of 16
							font_size = min(128, font_size + 2) # Limit to max of 128
							_update_font_size()
							get_tree().get_root().set_input_as_handled()
						elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN: # Decrease font size with ctrl+mouse wheel down
							if font_size <= 0:
								font_size = 16 # Use default font size of 16
							font_size = max(8, font_size - 2) # Limit to minimum of 8
							_update_font_size()
							get_tree().get_root().set_input_as_handled()


var suggestions := []
var current_suggest := 0
var suggesting := false

func autocomplete() -> void:
	if (suggesting):
		for i in range(suggestions.size()):
			if (current_suggest == i):
				line_edit.text = str(suggestions[i])
				line_edit.caret_column = line_edit.text.length()
				if (current_suggest == suggestions.size() - 1):
					current_suggest = 0
				else:
					current_suggest += 1
				return
	else:
		suggesting = true

		if (" " in line_edit.text): # We're searching for a parameter to autocomplete
			var split_text := parse_line_input(line_edit.text)
			if (split_text.size() > 1):
				var command := split_text[0]
				var param_input := split_text[1]
				if (command_parameters.has(command)):
					for param in command_parameters[command]:
						if (param_input in param):
							suggestions.append(str(command, " ", param))
		else:
			var sorted_commands := []
			for command in console_commands:
				if (!console_commands[command].hidden):
					sorted_commands.append(str(command))
			sorted_commands.sort()
			sorted_commands.reverse()

			var prev_index := 0
			for command in sorted_commands:
				if (!line_edit.text || command.contains(line_edit.text)):
					var index : int = command.find(line_edit.text)
					if (index <= prev_index):
						suggestions.push_front(command)
					else:
						suggestions.push_back(command)
					prev_index = index
		autocomplete()


func reset_autocomplete() -> void:
	suggestions.clear()
	current_suggest = 0
	suggesting = false


func toggle_size() -> void:
	if (control.anchor_bottom == 1.0):
		control.anchor_bottom = 1.9
	else:
		control.anchor_bottom = 1.0


func disable():
	enabled = false
	toggle_console() # Ensure hidden if opened


func enable():
	enabled = true


func toggle_console() -> void:
	if (enabled):
		control.visible = !control.visible
	else:
		control.visible = false

	if (control.visible):
		was_paused_already = get_tree().paused
		get_tree().paused = was_paused_already || pause_enabled
		line_edit.grab_focus()
		console_opened.emit()
	else:
		control.anchor_bottom = 1.0
		scroll_to_bottom()
		reset_autocomplete()
		if (pause_enabled && !was_paused_already):
			get_tree().paused = false
		console_closed.emit()


func is_visible():
	return control.visible


func scroll_to_bottom() -> void:
	var scroll: ScrollBar = rich_label.get_v_scroll_bar()
	scroll.value = scroll.max_value - scroll.page


func print_error(text : Variant, print_godot := false) -> void:
	if not text is String:
		text = str(text)
	print_line("[color=#ff4444]-bash: error:[/color] %s" % text, print_godot)


func print_info(text : Variant, print_godot := false) -> void:
	if not text is String:
		text = str(text)
	print_line("[color=#5555ff][info][/color] %s" % text, print_godot)


func print_warning(text : Variant, print_godot := false) -> void:
	if not text is String:
		text = str(text)
	print_line("[color=#ffff55]-bash: warning:[/color] %s" % text, print_godot)


func print_line(text : Variant, print_godot := false) -> void:
	if not text is String:
		text = str(text)
	if (!rich_label): # Tried to print something before the console was loaded.
		call_deferred("print_line", text)
	else:
		rich_label.append_text(text)
		rich_label.append_text("\n")
		if (print_godot):
			print_rich(text.dedent())


func parse_line_input(text : String) -> PackedStringArray:
	var out_array : PackedStringArray
	var first_char := true
	var in_quotes := false
	var escaped := false
	var token : String
	for c in text:
		if (c == '\\'):
			escaped = true
			continue
		elif (escaped):
			if (c == 'n'):
				c = '\n'
			elif (c == 't'):
				c = '\t'
			elif (c == 'r'):
				c = '\r'
			elif (c == 'a'):
				c = '\a'
			elif (c == 'b'):
				c = '\b'
			elif (c == 'f'):
				c = '\f'
			escaped = false
		elif (c == '\"'):
			in_quotes = !in_quotes
			continue
		elif (c == ' ' || c == '\t'):
			if (!in_quotes):
				out_array.push_back(token)
				token = ""
				continue
		token += c
	out_array.push_back(token)
	return out_array


func _on_text_entered(new_text : String) -> void:
	scroll_to_bottom()
	reset_autocomplete()
	line_edit.clear()
	if (line_edit.has_method(&"edit")):
		line_edit.call_deferred(&"edit")

	if not new_text.strip_edges().is_empty():
		add_input_history(new_text)
		print_line(_get_prompt() + " " + new_text)
		var text_split := parse_line_input(new_text)
		var text_command := text_split[0]

		if console_commands.has(text_command):
			var arguments := text_split.slice(1)
			var console_command : ConsoleCommand = console_commands[text_command]

			# calc is a especial command that needs special treatment
			if (text_command.match("calc")):
				var expression := ""
				for word in arguments:
					expression += word
				console_command.function.callv([expression])
				return

			if (arguments.size() < console_command.required):
				print_error("%s: missing operand. Required %d argument(s)" % [text_command, console_command.required])
				return
			elif (arguments.size() > console_command.arguments.size()):
				arguments.resize(console_command.arguments.size())

			# Functions fail to call if passed the incorrect number of arguments, so fill out with blank strings.
			while (arguments.size() < console_command.arguments.size()):
				arguments.append("")

			console_command.function.callv(arguments)
		else:
			console_unknown_command.emit(text_command)
			print_error("%s: command not found" % text_command)


func _on_line_edit_text_changed(new_text : String) -> void:
	reset_autocomplete()



func add_input_history(text : String) -> void:
	if (!console_history.size() || text != console_history.back()): # Don't add consecutive duplicates
		console_history.append(text)
	console_history_index = console_history.size()


func set_enable_on_release_build(enable : bool):
	enable_on_release_build = enable
	if (!enable_on_release_build):
		if (!OS.is_debug_build()):
			disable()


