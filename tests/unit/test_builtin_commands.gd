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
