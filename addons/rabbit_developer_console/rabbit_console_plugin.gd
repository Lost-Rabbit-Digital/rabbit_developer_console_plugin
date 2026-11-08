@tool
extends EditorPlugin

const CONSOLE_THEME : String = &"console/theme"
const CONSOLE_ENABLE_ON_RELEASE : String = &"console/enable_on_release_build"
const AUTOLOAD_NAME := "Console"
const AUTOLOAD_PATH := "res://addons/rabbit_developer_console/rabbit_console.gd"


func _enter_tree():
	var changed := false
	changed = _register_setting(CONSOLE_THEME, "", {
		"name": CONSOLE_THEME,
		"type": TYPE_STRING,
		"hint": PROPERTY_HINT_FILE,
		"hint_string": "*.tres",
	}) or changed
	changed = _register_setting(CONSOLE_ENABLE_ON_RELEASE, false, {
		"name": CONSOLE_ENABLE_ON_RELEASE,
		"type": TYPE_BOOL,
	}) or changed

	# The plugin is usually switched on by editing project.godot (the LRD Addon Manager does
	# this), which never calls _enable_plugin(), so make sure the autoload exists on load too.
	if str(ProjectSettings.get_setting("autoload/" + AUTOLOAD_NAME, "")).is_empty():
		add_autoload_singleton(AUTOLOAD_NAME, AUTOLOAD_PATH)
		# The editor only queues its own save, which never happens if it quits right away
		# (headless imports, CI), so save explicitly.
		changed = true

	# Only write project.godot when something was actually added, so opening the editor
	# doesn't rewrite it every time.
	if changed:
		ProjectSettings.save()


# The autoload is deliberately not removed in _exit_tree(): that also runs on editor quit and
# during command-line exports, where remove_autoload_singleton() can trip a CRASH_COND in
# remove_named_global_constant() (starbrew's Windows export aborted with SIGABRT / exit 134).
# It is removed only when the user actually disables the plugin.
func _disable_plugin():
	if _autoload_is_ours():
		remove_autoload_singleton(AUTOLOAD_NAME)


## True if the Console autoload points at this plugin's script (Godot 4.4+ may store it as a
## uid:// path), so disabling never removes a different "Console" singleton the game defines.
func _autoload_is_ours() -> bool:
	var path := str(ProjectSettings.get_setting("autoload/" + AUTOLOAD_NAME, "")).trim_prefix("*")
	if path.begins_with("uid://"):
		var id := ResourceUID.text_to_id(path)
		path = ResourceUID.get_id_path(id) if ResourceUID.has_id(id) else ""
	return path == AUTOLOAD_PATH


## Adds a project setting with its default if it's missing. Returns true if it was added.
func _register_setting(setting_name : String, default_value : Variant, info : Dictionary) -> bool:
	var added := false
	if not ProjectSettings.has_setting(setting_name):
		ProjectSettings.set_setting(setting_name, default_value)
		added = true
	ProjectSettings.add_property_info(info)
	ProjectSettings.set_initial_value(setting_name, default_value)
	ProjectSettings.set_as_basic(setting_name, true)
	return added
