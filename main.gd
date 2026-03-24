extends Control

# DVD Bouncer settings
var square_size := 80.0
var square_speed := 200.0
var square_color := Color.MAGENTA
var square_position := Vector2(100, 100)
var square_velocity := Vector2(1, 1).normalized()
var square_angle_deg := 45.0  # angle in degrees

func _ready() -> void:
	# Initialize velocity from angle and speed
	_update_velocity_from_angle()

	# Register console commands
	Console.add_command("dvd_speed", _cmd_speed, ["speed"], 1, "Set DVD square speed (pixels/sec). Example: dvd_speed 300")
	Console.add_command("dvd_size", _cmd_size, ["size"], 1, "Set DVD square size in pixels. Example: dvd_size 120")
	Console.add_command("dvd_color", _cmd_color, ["color"], 1, "Set DVD square color by name (red, green, blue, etc). Example: dvd_color cyan")
	Console.add_command("dvd_angle", _cmd_angle, ["degrees"], 1, "Set DVD square bounce angle in degrees. Example: dvd_angle 60")

	Console.add_command_autocomplete_list("dvd_color", PackedStringArray([
		"red", "green", "blue", "cyan", "magenta", "yellow", "white",
		"orange", "pink", "purple", "lime", "aqua"
	]))


func _exit_tree() -> void:
	Console.remove_command("dvd_speed")
	Console.remove_command("dvd_size")
	Console.remove_command("dvd_color")
	Console.remove_command("dvd_angle")


func _process(delta: float) -> void:
	var screen_size := get_viewport_rect().size

	# Move the square
	square_position += square_velocity * square_speed * delta

	# Bounce off edges and change color on hit
	var bounced := false

	if square_position.x <= 0:
		square_position.x = 0
		square_velocity.x = abs(square_velocity.x)
		bounced = true
	elif square_position.x + square_size >= screen_size.x:
		square_position.x = screen_size.x - square_size
		square_velocity.x = -abs(square_velocity.x)
		bounced = true

	if square_position.y <= 0:
		square_position.y = 0
		square_velocity.y = abs(square_velocity.y)
		bounced = true
	elif square_position.y + square_size >= screen_size.y:
		square_position.y = screen_size.y - square_size
		square_velocity.y = -abs(square_velocity.y)
		bounced = true

	if bounced:
		square_color = Color(randf(), randf(), randf())

	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(square_position, Vector2(square_size, square_size)), square_color)


func _update_velocity_from_angle() -> void:
	var rad := deg_to_rad(square_angle_deg)
	square_velocity = Vector2(cos(rad), sin(rad)).normalized()


# --- Console command callbacks ---

func _cmd_speed(value: String) -> void:
	var s := value.to_float()
	if s <= 0:
		Console.print_error("Speed must be a positive number.")
		return
	square_speed = s
	Console.print_line("DVD speed set to %s" % s)


func _cmd_size(value: String) -> void:
	var s := value.to_float()
	if s <= 0:
		Console.print_error("Size must be a positive number.")
		return
	square_size = s
	Console.print_line("DVD size set to %s" % s)


func _cmd_color(value: String) -> void:
	var c := Color.from_string(value, Color(-1, -1, -1))
	if c == Color(-1, -1, -1):
		Console.print_error("Unknown color '%s'. Try: red, green, blue, cyan, magenta, yellow, white, orange, pink, purple." % value)
		return
	square_color = c
	Console.print_line("DVD color set to %s" % value)


func _cmd_angle(value: String) -> void:
	var a := value.to_float()
	square_angle_deg = a
	_update_velocity_from_angle()
	Console.print_line("DVD angle set to %s degrees" % a)


func _on_quit_button_pressed() -> void:
	get_tree().quit()
