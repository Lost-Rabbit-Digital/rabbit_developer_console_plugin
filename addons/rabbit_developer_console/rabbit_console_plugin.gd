@tool
extends EditorPlugin

const CONSOLE_THEME : String = &"console/theme"

# True when this plugin registered the Console autoload (only when project.godot
# did not already declare it). Guards the teardown remove so Godot's
# remove_autoload_singleton() doesn't trip a CRASH_COND in
# remove_named_global_constant() during editor/export teardown (starbrew's
# Windows export aborted with SIGABRT / exit 134).
var _managed_autoload := false

func _enter_tree():
	if not ProjectSettings.has_setting(CONSOLE_THEME):
		ProjectSettings.set_setting(CONSOLE_THEME, "")

	ProjectSettings.add_property_info({
		"name": CONSOLE_THEME,
		"type": TYPE_STRING,
		"hint": PROPERTY_HINT_FILE,
		"hint_string": "*.tres",
	})

	ProjectSettings.set_initial_value(CONSOLE_THEME, "")
	ProjectSettings.set_as_basic(CONSOLE_THEME, true)
	ProjectSettings.save()

	if str(ProjectSettings.get_setting("autoload/Console", "")).is_empty():
		add_autoload_singleton("Console", "res://addons/rabbit_developer_console/rabbit_console.gd")
		_managed_autoload = true

	print("Console plugin activated.")

func _exit_tree():
	if _managed_autoload:
		remove_autoload_singleton("Console")
