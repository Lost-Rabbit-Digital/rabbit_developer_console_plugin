extends Control

# DVD Bouncer settings (shared defaults for new DVDs)
var dvd_speed := 200.0
var dvd_size := 80.0
var dvd_angle_deg := 45.0

# Each DVD is a Dictionary: { position: Vector2, velocity: Vector2, color: Color, size: float, speed: float }
var dvds: Array[Dictionary] = []


func _create_dvd_data() -> Dictionary:
	var screen_size := get_viewport_rect().size
	var pos := Vector2(randf_range(0, screen_size.x - dvd_size), randf_range(0, screen_size.y - dvd_size))
	var angle := randf_range(20, 70)
	var rad := deg_to_rad(angle)
	var vel := Vector2(cos(rad), sin(rad)).normalized()
	if randi() % 2 == 0:
		vel.x = -vel.x
	if randi() % 2 == 0:
		vel.y = -vel.y
	return {
		"position": pos,
		"velocity": vel,
		"color": Color(randf(), randf(), randf()),
		"size": dvd_size,
		"speed": dvd_speed,
	}


func _ready() -> void:
	# Start with one DVD
	dvds.append(_create_dvd_data())

	# Register console commands
	Console.add_command("dvd_speed", _cmd_speed, ["speed"], 1, "Set ALL DVD square speeds (pixels/sec). Example: dvd_speed 300")
	Console.add_command("dvd_size", _cmd_size, ["size"], 1, "Set ALL DVD square sizes in pixels. Example: dvd_size 120")
	Console.add_command("dvd_color", _cmd_color, ["color"], 1, "Set ALL DVD square colors by name (red, green, blue, etc). Example: dvd_color cyan")
	Console.add_command("dvd_angle", _cmd_angle, ["degrees"], 1, "Set ALL DVD square bounce angles in degrees. Example: dvd_angle 60")
	Console.add_command("create_dvd", _cmd_create_dvd, [], 0, "Spawn a new DVD square to bounce around the screen.")
	Console.add_command("delete_dvd", _cmd_delete_dvd, [], 0, "Remove one DVD square from the screen.")

	Console.add_command_autocomplete_list("dvd_color", PackedStringArray([
		"red", "green", "blue", "cyan", "magenta", "yellow", "white",
		"orange", "pink", "purple", "lime", "aqua"
	]))


func _exit_tree() -> void:
	Console.remove_command("dvd_speed")
	Console.remove_command("dvd_size")
	Console.remove_command("dvd_color")
	Console.remove_command("dvd_angle")
	Console.remove_command("create_dvd")
	Console.remove_command("delete_dvd")


func _process(delta: float) -> void:
	var screen_size := get_viewport_rect().size

	for dvd in dvds:
		var pos: Vector2 = dvd["position"]
		var vel: Vector2 = dvd["velocity"]
		var spd: float = dvd["speed"]
		var sz: float = dvd["size"]

		pos += vel * spd * delta

		var bounced := false

		if pos.x <= 0:
			pos.x = 0
			vel.x = abs(vel.x)
			bounced = true
		elif pos.x + sz >= screen_size.x:
			pos.x = screen_size.x - sz
			vel.x = -abs(vel.x)
			bounced = true

		if pos.y <= 0:
			pos.y = 0
			vel.y = abs(vel.y)
			bounced = true
		elif pos.y + sz >= screen_size.y:
			pos.y = screen_size.y - sz
			vel.y = -abs(vel.y)
			bounced = true

		if bounced:
			dvd["color"] = Color(randf(), randf(), randf())

		dvd["position"] = pos
		dvd["velocity"] = vel

	queue_redraw()


func _draw() -> void:
	for dvd in dvds:
		var sz: float = dvd["size"]
		draw_rect(Rect2(dvd["position"], Vector2(sz, sz)), dvd["color"])


# --- Console command callbacks ---

func _cmd_speed(value: String) -> void:
	var s := value.to_float()
	if s <= 0:
		Console.print_error("Speed must be a positive number.")
		return
	dvd_speed = s
	for dvd in dvds:
		dvd["speed"] = s
	Console.print_line("All DVD speeds set to %s" % s)


func _cmd_size(value: String) -> void:
	var s := value.to_float()
	if s <= 0:
		Console.print_error("Size must be a positive number.")
		return
	dvd_size = s
	for dvd in dvds:
		dvd["size"] = s
	Console.print_line("All DVD sizes set to %s" % s)


func _cmd_color(value: String) -> void:
	var c := Color.from_string(value, Color(-1, -1, -1))
	if c == Color(-1, -1, -1):
		Console.print_error("Unknown color '%s'. Try: red, green, blue, cyan, magenta, yellow, white, orange, pink, purple." % value)
		return
	for dvd in dvds:
		dvd["color"] = c
	Console.print_line("All DVD colors set to %s" % value)


func _cmd_angle(value: String) -> void:
	var a := value.to_float()
	dvd_angle_deg = a
	var rad := deg_to_rad(a)
	var vel := Vector2(cos(rad), sin(rad)).normalized()
	for dvd in dvds:
		dvd["velocity"] = vel
	Console.print_line("All DVD angles set to %s degrees" % a)


func _cmd_create_dvd() -> void:
	dvds.append(_create_dvd_data())
	Console.print_line("Created DVD. Total: %s" % dvds.size())


func _cmd_delete_dvd() -> void:
	if dvds.is_empty():
		Console.print_error("No DVDs to remove.")
		return
	dvds.pop_back()
	Console.print_line("Removed one DVD. Remaining: %s" % dvds.size())


func _on_quit_button_pressed() -> void:
	get_tree().quit()
