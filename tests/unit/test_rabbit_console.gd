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
	var opened_urls: Array = []
	func _is_release_build() -> bool:
		return fake_release
	func _open_external_url(url: String) -> void:
		opened_urls.append(url)


const TEST_ACTION := &"test_console_move_forward"


func before_test() -> void:
	DirAccess.remove_absolute(HISTORY)


func after_test() -> void:
	DirAccess.remove_absolute(HISTORY)
	if InputMap.has_action(TEST_ACTION):
		Input.action_release(TEST_ACTION)
		InputMap.erase_action(TEST_ACTION)


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


# ---- Links and untrusted text ----

func test_safe_external_url_accepts_web_links() -> void:
	var console := _make_console()
	for url in [
		"https://discord.gg/Y7caBf7gBj",
		"http://example.com",
		"HTTPS://Example.com/path?q=1#frag",
		"https://example.com:8443/a/b",
		"http://[::1]:8080/",
		"https://bücher.example/",
	]:
		assert_bool(console.is_safe_external_url(url)).override_failure_message(url).is_true()


func test_safe_external_url_rejects_everything_else() -> void:
	var console := _make_console()
	var bs := char(92)
	var q := char(34)
	for url in [
		"file:///C:/Windows/System32/calc.exe",
		"FILE:///etc/passwd",
		"javascript:alert(1)",
		"steam://run/440",
		"ms-settings:",
		"mailto:a@b.c",
		"C:" + bs + "Windows" + bs + "notepad.exe",
		bs + bs + "server" + bs + "share",
		"/usr/bin/xterm",
		"http://",
		"https:///path",
		" https://example.com",
		"https://example.com\nfile:///x",
		"https://exa mple.com",
		"https://example.com" + char(1) + ".evil",
		"https://good.example@evil.example/",
		"https://example.com:0/",
		"https://example.com:99999/",
		"https://example.com:-1/",
		"https://example.com:/",
		"https://example..com/",
		"https://example.com/" + bs + "..",
		"https://example.com/" + q + "onclick",
		"http://[::1",
	]:
		assert_bool(console.is_safe_external_url(url)).override_failure_message(url).is_false()


func test_clicked_file_link_is_not_opened() -> void:
	var console := _make_console()
	console._on_console_link_clicked("file:///C:/Windows/System32/calc.exe")
	console._on_console_link_clicked("steam://run/440")
	assert_array(console.opened_urls).is_empty()
	assert_str(console.rich_label.get_parsed_text()).contains("refused to open link")


func test_clicked_web_link_is_opened() -> void:
	var console := _make_console()
	console._on_console_link_clicked("https://example.com/docs")
	assert_array(console.opened_urls).is_equal(["https://example.com/docs"])


func test_print_plain_shows_bbcode_literally() -> void:
	var console := _make_console()
	var hostile := "[url=file:///C:/evil.exe]click[/url] [color=red]x[/color] ]["
	console.rich_label.clear()
	console.print_plain(hostile)
	assert_str(console.rich_label.get_parsed_text()).is_equal(hostile + "\n")


func test_entered_text_is_echoed_literally() -> void:
	# The echoed command line must not turn typed (or exec-script) BBCode into a live link.
	var console := _make_console()
	console.rich_label.clear()
	console._on_text_entered("[url=file:///C:/evil.exe]x[/url]")
	var shown: String = console.rich_label.get_parsed_text()
	assert_str(shown).contains("[url=file:///C:/evil.exe]x[/url]")
	assert_str(shown).contains("command not found")


# ---- Game input while the console is open ----

func _add_test_action() -> void:
	InputMap.add_action(TEST_ACTION)
	var key := InputEventKey.new()
	key.physical_keycode = KEY_W
	InputMap.action_add_event(TEST_ACTION, key)


func test_opening_console_releases_held_actions() -> void:
	_add_test_action()
	var console := _make_console()
	Input.action_press(TEST_ACTION)
	console.toggle_console()
	assert_bool(Input.is_action_pressed(TEST_ACTION)).is_false()


func test_actions_pressed_while_open_are_released_before_game_polls() -> void:
	_add_test_action()
	var console := _make_console()
	await await_idle_frame() # the input shield is attached deferred
	console.toggle_console()
	Input.action_press(TEST_ACTION) # what Input does when W goes down while typing
	console._input_shield._physics_process(0.0)
	assert_bool(Input.is_action_pressed(TEST_ACTION)).is_false()
	Input.action_press(TEST_ACTION)
	console._input_shield._process(0.0)
	assert_bool(Input.is_action_pressed(TEST_ACTION)).is_false()


func test_input_shield_runs_before_game_nodes() -> void:
	var console := _make_console()
	await await_idle_frame()
	assert_object(console._input_shield).is_not_null()
	assert_object(console._input_shield.get_parent()).is_same(get_tree().root)
	assert_int(console._input_shield.process_priority).is_less(0)
	assert_int(console._input_shield.process_physics_priority).is_less(0)


func test_actions_are_left_alone_when_blocking_is_off() -> void:
	_add_test_action()
	var console := _make_console()
	await await_idle_frame()
	console.block_game_input = false
	Input.action_press(TEST_ACTION)
	console.toggle_console()
	console._input_shield._process(0.0)
	assert_bool(Input.is_action_pressed(TEST_ACTION)).is_true()


func test_actions_are_left_alone_when_console_is_closed() -> void:
	_add_test_action()
	var console := _make_console()
	await await_idle_frame()
	Input.action_press(TEST_ACTION)
	console._input_shield._process(0.0)
	assert_bool(Input.is_action_pressed(TEST_ACTION)).is_true()


class UnhandledRecorder extends Node:
	var events: Array = []
	func _unhandled_input(event: InputEvent) -> void:
		events.append(event)


func _key(keycode: Key, pressed: bool) -> InputEventKey:
	var ev := InputEventKey.new()
	ev.keycode = keycode
	ev.physical_keycode = keycode
	ev.pressed = pressed
	return ev


func test_keys_typed_into_console_do_not_reach_game_unhandled_input() -> void:
	var console := _make_console()
	var game := UnhandledRecorder.new()
	add_child(auto_free(game))
	await await_idle_frame()
	console.toggle_console()
	# LineEdit takes key presses but ignores releases and keys it has no use for (F5, ...);
	# without the shield those would reach the game's _unhandled_input().
	get_tree().root.push_input(_key(KEY_W, false))
	get_tree().root.push_input(_key(KEY_F5, true))
	assert_array(game.events).is_empty()
	console.toggle_console()
	get_tree().root.push_input(_key(KEY_F5, true))
	assert_int(game.events.size()).is_equal(1)


# ---- Dropdown hints ----

func test_dropdown_completes_parameters_of_multi_word_commands() -> void:
	var console := _make_console()
	var rec := Recorder.new()
	console.add_command("spawn_enemy", rec.record, ["kind"], 1)
	console.add_command_autocomplete_list("spawn_enemy", PackedStringArray(["goblin", "golem", "slime"]))
	assert_array(Array(console._get_dropdown_matches("spawn enemy go"))).is_equal(["spawn enemy goblin", "spawn enemy golem"])
	assert_array(Array(console._get_dropdown_matches("spawn enemy "))).is_equal(["spawn enemy goblin", "spawn enemy golem", "spawn enemy slime"])
	assert_array(Array(console._get_dropdown_matches("spawn_enemy sl"))).is_equal(["spawn_enemy slime"])


func test_dropdown_still_completes_single_word_command_parameters() -> void:
	var console := _make_console()
	assert_array(Array(console._get_dropdown_matches("vsync ad"))).is_equal(["vsync adaptive"])


func test_dropdown_matches_partly_typed_multi_word_command_names() -> void:
	var console := _make_console()
	assert_array(Array(console._get_dropdown_matches("echo wa"))).contains(["echo_warning"])
