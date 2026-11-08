## Unit tests for built-in console commands that touch the file system.
extends GdUnitTestSuite

const ConsoleScript := preload("res://addons/rabbit_developer_console/rabbit_console.gd")
const SCENES_DIR := "user://test_scene_listing"


func _make_console() -> Node:
	var console := ConsoleScript.new()
	console.history_file_path = "user://test_builtin_history.txt"
	add_child(auto_free(console))
	return console


func _write(path: String, text: String) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(text)
	f.close()


func after_test() -> void:
	for f in ["user://test_builtin_history.txt", "user://test_exec_self.txt"]:
		DirAccess.remove_absolute(f)
	if DirAccess.dir_exists_absolute(SCENES_DIR):
		for sub in [SCENES_DIR + "/levels", SCENES_DIR]:
			var dir := DirAccess.open(sub)
			if dir:
				for file in dir.get_files():
					dir.remove(file)
			DirAccess.remove_absolute(sub)


func test_scene_listing_includes_exported_remapped_scenes() -> void:
	# Exports list scenes as "<name>.tscn.remap"; the editor lists plain ".tscn".
	DirAccess.make_dir_recursive_absolute(SCENES_DIR + "/levels")
	_write(SCENES_DIR + "/menu.tscn", "")
	_write(SCENES_DIR + "/levels/level_1.tscn.remap", "")
	_write(SCENES_DIR + "/levels/level_2.tscn", "")
	_write(SCENES_DIR + "/levels/level_2.tscn.remap", "")
	_write(SCENES_DIR + "/notes.txt", "")
	var console := _make_console()
	var found := Array(console._builtin_commands._find_files_recursive(SCENES_DIR, ".tscn"))
	found.sort()
	assert_array(found).is_equal([
		SCENES_DIR + "/levels/level_1.tscn",
		SCENES_DIR + "/levels/level_2.tscn",
		SCENES_DIR + "/menu.tscn",
	])


func test_exec_that_runs_itself_stops_instead_of_overflowing() -> void:
	_write("user://test_exec_self.txt", "exec test_exec_self\n")
	var console := _make_console()
	console._on_text_entered("exec test_exec_self")
	assert_str(console.rich_label.get_parsed_text()).contains("nested too deep")
	assert_int(console._builtin_commands._exec_depth).is_equal(0)


func test_exec_rejects_paths_outside_user_dir() -> void:
	var console := _make_console()
	console._on_text_entered("exec ../../secrets")
	assert_str(console.rich_label.get_parsed_text()).contains("must be inside user://")


# ---- calc ----

func _calc(console: Node, expression: String) -> String:
	console.rich_label.clear()
	console._on_text_entered("calc " + expression)
	var lines: PackedStringArray = console.rich_label.get_parsed_text().strip_edges().split("\n")
	return lines[lines.size() - 1]


func test_calc_divides_like_a_calculator() -> void:
	var console := _make_console()
	assert_str(_calc(console, "10 / 4")).is_equal("2.5")
	assert_str(_calc(console, "10/4")).is_equal("2.5")
	assert_str(_calc(console, "(1 + 2) / 2")).is_equal("1.5")
	assert_str(_calc(console, "1 / 3")).starts_with("0.333")


func test_calc_keeps_whole_number_results_tidy() -> void:
	var console := _make_console()
	assert_str(_calc(console, "2 + 2")).is_equal("4")
	assert_str(_calc(console, "8 / 2")).is_equal("4")
	assert_str(_calc(console, "sqrt(144)")).is_equal("12")
	assert_str(_calc(console, "2.0 + 2")).is_equal("4.0")
	assert_str(_calc(console, "int(10 / 4)")).is_equal("2")


func test_calc_uses_the_expression_as_typed() -> void:
	var console := _make_console()
	# The words used to be re-joined without spaces after quote processing, so string literals
	# lost their quotes and spaces ("a b+c", a parse error).
	assert_str(_calc(console, "\"a b\" + \"c\"")).is_equal("a bc")
	assert_str(_calc(console, "1 - -1")).is_equal("2")


func test_calc_integer_operators_still_work() -> void:
	var console := _make_console()
	assert_str(_calc(console, "7 % 3")).is_equal("1")
	assert_str(_calc(console, "1 << 4")).is_equal("16")
	assert_str(_calc(console, "0xFF + 1")).is_equal("256")
	assert_str(_calc(console, "6 & 3")).is_equal("2")


func test_calc_reports_errors() -> void:
	var console := _make_console()
	assert_str(_calc(console, "1 / 0")).contains("error")
	assert_str(_calc(console, "2 +")).contains("error")


func test_calc_promotes_only_integer_literals() -> void:
	var console := _make_console()
	var builtins = console._builtin_commands
	assert_str(builtins._promote_int_literals("10 / 4")).is_equal("10.0 / 4.0")
	assert_str(builtins._promote_int_literals("1.5 + 2e3 + .5")).is_equal("1.5 + 2e3 + .5")
	assert_str(builtins._promote_int_literals("Vector2(1, 2).x + atan2(1, 0x10)")).is_equal("Vector2(1.0, 2.0).x + atan2(1.0, 0x10)")
	assert_str(builtins._promote_int_literals("\"10\" + str(4)")).is_equal("\"10\" + str(4.0)")
