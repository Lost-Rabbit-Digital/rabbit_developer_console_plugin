## Unit tests for the developer console: release-build lockout, command line parsing and
## command dispatch. Each test builds its own console instance (not the Console autoload) with a
## throwaway history file.
extends GdUnitTestSuite

const ConsoleScript := preload("res://addons/rabbit_developer_console/rabbit_console.gd")
const HISTORY := "user://test_console_history.txt"


## A console whose release check can be forced, so release behaviour can be tested from a
## debug editor binary.
class FakeBuildConsole extends "res://addons/rabbit_developer_console/rabbit_console.gd":
	var fake_release := false
	func _is_release_build() -> bool:
		return fake_release


func before_test() -> void:
	DirAccess.remove_absolute(HISTORY)


func after_test() -> void:
	DirAccess.remove_absolute(HISTORY)


func _make_console(release := false, opt_in := false) -> Node:
	var console := FakeBuildConsole.new()
	console.fake_release = release
	console.history_file_path = HISTORY
	if opt_in:
		console.enable_on_release_build = true
	add_child(auto_free(console))
	return console


func _press(console: Node, keycode: Key) -> void:
	var ev := InputEventKey.new()
	ev.physical_keycode = keycode
	ev.pressed = true
	console._input(ev)


# ---- Release builds ----

func test_debug_build_is_enabled_by_default() -> void:
	var console := _make_console(false)
	assert_bool(console.enabled).is_true()
	_press(console, KEY_QUOTELEFT)
	assert_bool(console.is_visible()).is_true()


func test_release_build_is_locked_by_default() -> void:
	var console := _make_console(true)
	assert_bool(console.enabled).is_false()
	_press(console, KEY_QUOTELEFT)
	assert_bool(console.is_visible()).is_false()
	console.toggle_console()
	assert_bool(console.is_visible()).is_false()


func test_release_build_opt_in_before_start() -> void:
	var console := _make_console(true, true)
	assert_bool(console.enabled).is_true()
	_press(console, KEY_QUOTELEFT)
	assert_bool(console.is_visible()).is_true()


func test_release_build_opt_in_after_start_unlocks() -> void:
	# Game scripts run after the Console autoload is ready, so this is the usual way to opt in.
	var console := _make_console(true)
	console.enable_on_release_build = true
	assert_bool(console.enabled).is_true()
	_press(console, KEY_QUOTELEFT)
	assert_bool(console.is_visible()).is_true()


func test_release_build_opt_out_at_runtime_closes_and_locks() -> void:
	var console := _make_console(true, true)
	console.toggle_console()
	assert_bool(console.is_visible()).is_true()
	console.enable_on_release_build = false
	assert_bool(console.enabled).is_false()
	assert_bool(console.is_visible()).is_false()


func test_opt_in_does_not_override_explicit_disable() -> void:
	var console := _make_console(true, true)
	console.disable()
	console.enable_on_release_build = true
	assert_bool(console.enabled).is_false()


func test_release_lock_skips_history_file() -> void:
	var console := _make_console(true)
	console.add_input_history("secret_cheat")
	remove_child(console) # runs _exit_tree, which saves history in debug builds
	assert_bool(FileAccess.file_exists(HISTORY)).is_false()


func test_debug_build_saves_history_file() -> void:
	var console := _make_console(false)
	console.add_input_history("help")
	remove_child(console)
	assert_bool(FileAccess.file_exists(HISTORY)).is_true()


func test_disable_while_closed_does_not_unpause_game() -> void:
	var console := _make_console(false)
	console.pause_enabled = true
	get_tree().paused = true # paused by the game's own pause menu
	console.disable()
	assert_bool(get_tree().paused).is_true()
	get_tree().paused = false


# ---- Parsing ----

func _parse(text: String) -> Array:
	var console := _make_console()
	return Array(console.parse_line_input(text))


func test_parse_simple_words() -> void:
	assert_array(_parse("load scene level_1")).is_equal(["load", "scene", "level_1"])


func test_parse_collapses_repeated_and_edge_whitespace() -> void:
	assert_array(_parse("  god   mode  ")).is_equal(["god", "mode"])
	assert_array(_parse("echo\t\thi")).is_equal(["echo", "hi"])
	assert_array(_parse("")).is_empty()


func test_parse_quotes_group_and_allow_empty_argument() -> void:
	assert_array(_parse("echo \"hello world\"")).is_equal(["echo", "hello world"])
	assert_array(_parse("give \"\" 3")).is_equal(["give", "", "3"])


func test_parse_escapes() -> void:
	var bs := char(92)
	assert_array(_parse("echo a" + bs + "nb")).is_equal(["echo", "a\nb"])
	assert_array(_parse("echo " + bs + "\"quoted" + bs + "\"")).is_equal(["echo", "\"quoted\""])
	assert_array(_parse("echo a" + bs + " b")).is_equal(["echo", "a b"])
	# A doubled backslash is one literal backslash, not an escape of the next letter.
	assert_array(_parse("echo C:" + bs + bs + "bin")).is_equal(["echo", "C:" + bs + "bin"])
	assert_array(_parse("echo end" + bs)).is_equal(["echo", "end" + bs])


# ---- Dispatch ----

class Recorder:
	var calls: Array = []
	func record(a: String = "", b: String = "") -> void:
		calls.append([a, b])


func test_multi_word_command_with_extra_spaces_dispatches() -> void:
	var console := _make_console()
	var rec := Recorder.new()
	console.add_command("god_mode", rec.record, ["a", "b"], 0, "", ["x", "y"])
	console._on_text_entered("god  mode   1")
	assert_array(rec.calls).is_equal([["1", "y"]])


func test_trailing_space_does_not_satisfy_required_argument() -> void:
	var console := _make_console()
	var rec := Recorder.new()
	console.add_command("teleport", rec.record, ["a", "b"], 1)
	console._on_text_entered("teleport ")
	assert_array(rec.calls).is_empty()
	console._on_text_entered("teleport 5")
	assert_array(rec.calls).is_equal([["5", ""]])


func test_excess_arguments_join_into_last() -> void:
	var console := _make_console()
	var rec := Recorder.new()
	console.add_command("say", rec.record, ["who", "text"], 1)
	console._on_text_entered("say bob hello there  world")
	assert_array(rec.calls).is_equal([["bob", "hello there world"]])


func test_shorthand_alias_resolves() -> void:
	var console := _make_console()
	var result: Array = console._match_command_from_tokens(PackedStringArray(["tree"]))
	assert_str(result[0]).is_equal("print_tree")
	assert_int(result[1]).is_equal(1)


func test_unknown_command_emits_signal() -> void:
	var console := _make_console()
	var monitor := monitor_signals(console, false)
	console._on_text_entered("definitely_not_a_command")
	await assert_signal(monitor).is_emitted("console_unknown_command", ["definitely_not_a_command"])
