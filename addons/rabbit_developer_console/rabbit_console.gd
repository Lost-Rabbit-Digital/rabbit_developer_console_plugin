extends Node

var enabled := true
var enable_on_release_build := false : set = set_enable_on_release_build
var pause_enabled := false
var font_size := -1:
	set(value):
		font_size = value
		_update_font_size()
enum ConsolePosition { FULL, BOTTOM, TOP, LEFT, RIGHT }
var console_position : ConsolePosition = ConsolePosition.BOTTOM
var bg_transparency := 0.85

var _panel_style : StyleBoxFlat
var _line_edit_style : StyleBoxFlat

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

var _dropdown_panel := Panel.new()
var _dropdown_vbox := VBoxContainer.new()
var _dropdown_style : StyleBoxFlat
var _dropdown_matches : Array[String] = []
var _dropdown_selected := -1
const _MAX_DROPDOWN_ITEMS := 12
const _DROPDOWN_ITEM_HEIGHT := 24

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
	canvas_layer.add_child(control)
	_apply_position()
	control.add_child(panel)
	panel.anchor_right = 1.0
	panel.anchor_bottom = 1.0
	panel.offset_bottom = -30

	# Terminal-style dark background for the panel
	_panel_style = StyleBoxFlat.new()
	_panel_style.bg_color = Color(0.07, 0.07, 0.07, bg_transparency)
	_panel_style.border_color = Color(0.2, 0.2, 0.2, 1.0)
	_panel_style.set_border_width_all(1)
	panel.add_theme_stylebox_override("panel", _panel_style)

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
	line_edit.anchor_top = 1.0
	line_edit.anchor_right = 1.0
	line_edit.anchor_bottom = 1.0
	line_edit.offset_top = -30
	line_edit.placeholder_text = "Type 'help' for a list of commands"

	# Terminal-style input field
	_line_edit_style = StyleBoxFlat.new()
	_line_edit_style.bg_color = Color(0.05, 0.05, 0.05, bg_transparency)
	_line_edit_style.border_color = Color(0.2, 0.2, 0.2, 1.0)
	_line_edit_style.set_border_width_all(1)
	_line_edit_style.content_margin_left = 8
	line_edit.add_theme_stylebox_override("normal", _line_edit_style)
	line_edit.add_theme_stylebox_override("focus", _line_edit_style)
	line_edit.add_theme_color_override("font_color", Color(0.0, 1.0, 0.0, 1.0))
	line_edit.add_theme_color_override("font_placeholder_color", Color(0.4, 0.4, 0.4, 1.0))
	line_edit.add_theme_color_override("caret_color", Color(0.0, 1.0, 0.0, 1.0))

	if font_size > 0:
		line_edit.add_theme_font_size_override("font_size", font_size)
	control.add_child(line_edit)

	# Command hint dropdown
	_dropdown_style = StyleBoxFlat.new()
	_dropdown_style.bg_color = Color(0.07, 0.07, 0.07, 0.97)
	_dropdown_style.border_color = Color(0.0, 0.8, 0.0, 0.6)
	_dropdown_style.set_border_width_all(1)
	_dropdown_style.content_margin_left = 2
	_dropdown_style.content_margin_right = 2
	_dropdown_style.content_margin_top = 2
	_dropdown_style.content_margin_bottom = 2
	_dropdown_panel.add_theme_stylebox_override("panel", _dropdown_style)
	_dropdown_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_dropdown_panel.visible = false
	_dropdown_panel.anchor_left = 0.0
	_dropdown_panel.anchor_top = 1.0
	_dropdown_panel.anchor_right = 0.0
	_dropdown_panel.anchor_bottom = 1.0
	_dropdown_panel.offset_left = 0
	_dropdown_panel.offset_right = 300
	_dropdown_panel.offset_bottom = -30

	_dropdown_vbox.anchor_right = 1.0
	_dropdown_vbox.anchor_bottom = 1.0
	_dropdown_panel.add_child(_dropdown_vbox)
	control.add_child(_dropdown_panel)

	line_edit.text_submitted.connect(_on_text_entered)
	line_edit.text_changed.connect(_on_line_edit_text_changed)
	control.visible = false
	process_mode = PROCESS_MODE_ALWAYS


func _get_hostname() -> String:
	return ProjectSettings.get_setting("application/config/name", "localhost")


func _get_prompt() -> String:
	return "[color=#00ff00]user[/color][color=#cccccc]:[/color][color=#5c5cff]~[/color][color=#cccccc]$[/color]"


func _get_plugin_version() -> String:
	var config := ConfigFile.new()
	if config.load("res://addons/rabbit_developer_console/plugin.cfg") == OK:
		return config.get_value("plugin", "version", "unknown")
	return "unknown"


func _print_motd() -> void:
	var hostname := _get_hostname()
	var plugin_version := _get_plugin_version()
	rich_label.append_text("[color=#cccccc]Welcome to %s console v%s[/color]\n" % [hostname, plugin_version])
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
				if _dropdown_panel.visible and _dropdown_matches.size() > 0:
					_dropdown_selected = wrapi(_dropdown_selected - 1, 0, mini(_dropdown_matches.size(), _MAX_DROPDOWN_ITEMS))
					_highlight_dropdown_item(_dropdown_selected)
					line_edit.text = _dropdown_matches[_dropdown_selected]
					line_edit.caret_column = line_edit.text.length()
				elif (console_history_index > 0):
					console_history_index -= 1
					if (console_history_index >= 0):
						line_edit.text = console_history[console_history_index]
						line_edit.caret_column = line_edit.text.length()
						reset_autocomplete()
			if (event.get_physical_keycode_with_modifiers() == KEY_DOWN):
				get_tree().get_root().set_input_as_handled()
				if _dropdown_panel.visible and _dropdown_matches.size() > 0:
					_dropdown_selected = wrapi(_dropdown_selected + 1, 0, mini(_dropdown_matches.size(), _MAX_DROPDOWN_ITEMS))
					_highlight_dropdown_item(_dropdown_selected)
					line_edit.text = _dropdown_matches[_dropdown_selected]
					line_edit.caret_column = line_edit.text.length()
				elif (console_history_index < console_history.size()):
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
				var cmd_match := _match_command_from_tokens(split_text)
				var matched_cmd : String = cmd_match[0]
				var consumed : int = cmd_match[1]
				if matched_cmd != "" and consumed < split_text.size():
					var param_input := split_text[consumed]
					if (command_parameters.has(matched_cmd)):
						var cmd_display := matched_cmd.replace("_", " ")
						for param in command_parameters[matched_cmd]:
							if (param_input in param):
								suggestions.append(str(cmd_display, " ", param))
		else:
			var sorted_commands := []
			for command in console_commands:
				if (!console_commands[command].hidden):
					sorted_commands.append(command.replace("_", " "))
			sorted_commands.sort()
			sorted_commands.reverse()

			var search_text := line_edit.text.replace("_", " ")
			var prev_index := 0
			for command_display in sorted_commands:
				if (!search_text || command_display.contains(search_text)):
					var index : int = command_display.find(search_text)
					if (index <= prev_index):
						suggestions.push_front(command_display)
					else:
						suggestions.push_back(command_display)
					prev_index = index
		autocomplete()


func reset_autocomplete() -> void:
	suggestions.clear()
	current_suggest = 0
	suggesting = false


func toggle_size() -> void:
	console_position = wrapi(console_position + 1, 0, ConsolePosition.size()) as ConsolePosition
	_apply_position()


func set_console_position(position : ConsolePosition) -> void:
	console_position = position
	_apply_position()


func _apply_position() -> void:
	match console_position:
		ConsolePosition.FULL:
			control.anchor_left = 0.0
			control.anchor_top = 0.0
			control.anchor_right = 1.0
			control.anchor_bottom = 1.0
		ConsolePosition.BOTTOM:
			control.anchor_left = 0.0
			control.anchor_top = 0.5
			control.anchor_right = 1.0
			control.anchor_bottom = 1.0
		ConsolePosition.TOP:
			control.anchor_left = 0.0
			control.anchor_top = 0.0
			control.anchor_right = 1.0
			control.anchor_bottom = 0.5
		ConsolePosition.LEFT:
			control.anchor_left = 0.0
			control.anchor_top = 0.0
			control.anchor_right = 0.5
			control.anchor_bottom = 1.0
		ConsolePosition.RIGHT:
			control.anchor_left = 0.5
			control.anchor_top = 0.0
			control.anchor_right = 1.0
			control.anchor_bottom = 1.0
	control.offset_left = 0
	control.offset_top = 0
	control.offset_right = 0
	control.offset_bottom = 0


func set_bg_transparency(value : float) -> void:
	bg_transparency = clampf(value, 0.0, 1.0)
	if _panel_style:
		_panel_style.bg_color.a = bg_transparency
	if _line_edit_style:
		_line_edit_style.bg_color.a = bg_transparency


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
		_apply_position()
		line_edit.grab_focus()
		console_opened.emit()
	else:
		scroll_to_bottom()
		reset_autocomplete()
		_dropdown_panel.visible = false
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


# Returns [command_name, num_tokens_consumed] for the longest matching command
# formed by joining tokens with underscores. Returns ["", 0] if no match found.
func _match_command_from_tokens(tokens : PackedStringArray) -> Array:
	var best_match := ""
	var best_count := 0
	for i in range(1, tokens.size() + 1):
		var candidate := "_".join(tokens.slice(0, i))
		if console_commands.has(candidate):
			best_match = candidate
			best_count = i
	return [best_match, best_count]


func _on_text_entered(new_text : String) -> void:
	scroll_to_bottom()
	reset_autocomplete()
	_dropdown_panel.visible = false
	_dropdown_matches.clear()
	_dropdown_selected = -1
	line_edit.clear()
	if (line_edit.has_method(&"edit")):
		line_edit.call_deferred(&"edit")

	if not new_text.strip_edges().is_empty():
		add_input_history(new_text)
		print_line(_get_prompt() + " " + new_text)
		var text_split := parse_line_input(new_text)
		var match_result := _match_command_from_tokens(text_split)
		var text_command : String = match_result[0]
		var tokens_consumed : int = match_result[1]

		if text_command != "":
			var arguments := text_split.slice(tokens_consumed)
			var console_command : ConsoleCommand = console_commands[text_command]

			# calc is a especial command that needs special treatment
			if (text_command.match("calc")):
				var expression := ""
				for word in arguments:
					expression += word
				console_command.function.callv([expression])
				return

			if (arguments.size() < console_command.required):
				print_error("%s: missing operand. Required %d argument(s)" % [text_command.replace("_", " "), console_command.required])
				return
			elif (arguments.size() > console_command.arguments.size()):
				arguments.resize(console_command.arguments.size())

			# Functions fail to call if passed the incorrect number of arguments, so fill out with blank strings.
			while (arguments.size() < console_command.arguments.size()):
				arguments.append("")

			console_command.function.callv(arguments)
		else:
			var first_token := text_split[0]
			console_unknown_command.emit(first_token)
			print_error("%s: command not found" % first_token)
			var suggestion := _find_similar_command("_".join(text_split))
			if suggestion != "":
				print_line("[color=#cccccc]-bash: did you mean '[color=#00ff00]%s[/color]'?[/color]" % suggestion.replace("_", " "))


func _on_line_edit_text_changed(new_text : String) -> void:
	reset_autocomplete()
	_dropdown_selected = -1
	_update_dropdown(new_text)



func _get_dropdown_matches(text : String) -> Array[String]:
	var matches : Array[String] = []
	if " " in text:
		var split := parse_line_input(text)
		if split.size() >= 1:
			var command := split[0]
			var param_input := split[split.size() - 1] if split.size() >= 2 else ""
			if command_parameters.has(command):
				for param in command_parameters[command]:
					if param_input.is_empty() or param.begins_with(param_input) or param.contains(param_input):
						matches.append(command + " " + param)
	else:
		var prefix_matches : Array[String] = []
		var contains_matches : Array[String] = []
		var sorted_names : Array[String] = []
		for cmd_name in console_commands:
			if not console_commands[cmd_name].hidden:
				sorted_names.append(cmd_name)
		sorted_names.sort()
		for cmd_name in sorted_names:
			if cmd_name.begins_with(text):
				prefix_matches.append(cmd_name)
			elif cmd_name.contains(text):
				contains_matches.append(cmd_name)
		matches.assign(prefix_matches + contains_matches)
	return matches


func _update_dropdown(text : String) -> void:
	for child in _dropdown_vbox.get_children():
		child.queue_free()
	_dropdown_matches.clear()

	if text.is_empty():
		_dropdown_panel.visible = false
		return

	_dropdown_matches = _get_dropdown_matches(text)

	if _dropdown_matches.is_empty():
		_dropdown_panel.visible = false
		return

	var item_fs : int = font_size if font_size > 0 else 14
	var item_height : int = maxi(_DROPDOWN_ITEM_HEIGHT, item_fs + 8)
	var display_count := mini(_dropdown_matches.size(), _MAX_DROPDOWN_ITEMS)

	for i in range(display_count):
		var match_text : String = _dropdown_matches[i]
		var btn := Button.new()
		btn.text = match_text
		btn.flat = true
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.focus_mode = Control.FOCUS_NONE
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		btn.custom_minimum_size = Vector2(0, item_height)
		btn.add_theme_color_override("font_color", Color(0.0, 1.0, 0.0, 1.0))
		btn.add_theme_color_override("font_hover_color", Color(0.4, 1.0, 0.4, 1.0))
		btn.add_theme_color_override("font_pressed_color", Color(1.0, 1.0, 1.0, 1.0))
		var hover_style := StyleBoxFlat.new()
		hover_style.bg_color = Color(0.1, 0.2, 0.1, 1.0)
		hover_style.content_margin_left = 6
		btn.add_theme_stylebox_override("hover", hover_style)
		var normal_style := StyleBoxFlat.new()
		normal_style.bg_color = Color(0.0, 0.0, 0.0, 0.0)
		normal_style.content_margin_left = 6
		btn.add_theme_stylebox_override("normal", normal_style)
		btn.add_theme_stylebox_override("pressed", hover_style)
		btn.add_theme_stylebox_override("focus", normal_style)
		if font_size > 0:
			btn.add_theme_font_size_override("font_size", font_size)
		btn.pressed.connect(_on_dropdown_item_pressed.bind(match_text))
		_dropdown_vbox.add_child(btn)

	var panel_height := display_count * item_height + 4
	_dropdown_panel.offset_top = -30 - panel_height
	_dropdown_panel.offset_right = 300
	_dropdown_panel.visible = true


func _highlight_dropdown_item(index : int) -> void:
	var children := _dropdown_vbox.get_children()
	for i in range(children.size()):
		var btn := children[i] as Button
		if btn == null:
			continue
		if i == index:
			var sel_style := StyleBoxFlat.new()
			sel_style.bg_color = Color(0.1, 0.3, 0.1, 1.0)
			sel_style.content_margin_left = 6
			btn.add_theme_stylebox_override("normal", sel_style)
		else:
			var normal_style := StyleBoxFlat.new()
			normal_style.bg_color = Color(0.0, 0.0, 0.0, 0.0)
			normal_style.content_margin_left = 6
			btn.add_theme_stylebox_override("normal", normal_style)


func _on_dropdown_item_pressed(match_text : String) -> void:
	line_edit.text = match_text + " "
	line_edit.caret_column = line_edit.text.length()
	line_edit.grab_focus()
	_dropdown_panel.visible = false
	_dropdown_matches.clear()
	_dropdown_selected = -1
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


func _find_similar_command(input : String) -> String:
	var best_match := ""
	var best_distance := INF
	var max_distance : int = max(3, ceili(input.length() * 0.5))
	for command_name in console_commands:
		if console_commands[command_name].hidden:
			continue
		var dist := _levenshtein_distance(input.to_lower(), command_name.to_lower())
		if dist < best_distance:
			best_distance = dist
			best_match = command_name
	if best_distance <= max_distance:
		return best_match
	return ""


func _levenshtein_distance(a : String, b : String) -> int:
	var len_a := a.length()
	var len_b := b.length()
	if len_a == 0:
		return len_b
	if len_b == 0:
		return len_a
	var prev_row : Array[int] = []
	prev_row.resize(len_b + 1)
	for j in range(len_b + 1):
		prev_row[j] = j
	for i in range(1, len_a + 1):
		var curr_row : Array[int] = []
		curr_row.resize(len_b + 1)
		curr_row[0] = i
		for j in range(1, len_b + 1):
			var cost := 0 if a[i - 1] == b[j - 1] else 1
			curr_row[j] = mini(mini(curr_row[j - 1] + 1, prev_row[j] + 1), prev_row[j - 1] + cost)
		prev_row = curr_row
	return prev_row[len_b]


