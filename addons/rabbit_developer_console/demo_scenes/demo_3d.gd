extends Node3D

# DVD Bouncer 3D settings (shared defaults for new DVDs)
var dvd_speed := 5.0
var dvd_size := 1.0
var dvd_angle_deg := 45.0

# Each DVD is a Dictionary: { mesh_instance: MeshInstance3D, velocity: Vector3, color: Color }
var dvds: Array[Dictionary] = []

# Bounding box for bouncing
var bounds := Vector3(10.0, 6.0, 10.0)


func _create_dvd_data() -> Dictionary:
	var pos := Vector3(
		randf_range(-bounds.x + dvd_size, bounds.x - dvd_size),
		randf_range(-bounds.y + dvd_size, bounds.y - dvd_size),
		randf_range(-bounds.z + dvd_size, bounds.z - dvd_size)
	)
	var vel := Vector3(
		randf_range(-1.0, 1.0),
		randf_range(-1.0, 1.0),
		randf_range(-1.0, 1.0)
	).normalized()

	var color := Color(randf(), randf(), randf())

	var mesh_instance := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3.ONE * dvd_size
	mesh_instance.mesh = box
	mesh_instance.position = pos

	var material := StandardMaterial3D.new()
	material.albedo_color = color
	mesh_instance.material_override = material

	add_child(mesh_instance)

	return {
		"mesh_instance": mesh_instance,
		"velocity": vel,
		"color": color,
	}


func _ready() -> void:
	# Start with one DVD
	dvds.append(_create_dvd_data())

	# Register console commands
	Console.add_command("dvd_speed", _cmd_speed, ["speed"], 1, "Set ALL DVD cube speeds. Example: dvd_speed 8")
	Console.add_command("dvd_size", _cmd_size, ["size"], 1, "Set ALL DVD cube sizes. Example: dvd_size 2")
	Console.add_command("dvd_color", _cmd_color, ["color"], 1, "Set ALL DVD cube colors by name (red, green, blue, etc). Example: dvd_color cyan")
	Console.add_command("dvd_angle", _cmd_angle, ["degrees"], 1, "Set ALL DVD cube bounce angles in degrees. Example: dvd_angle 60")
	Console.add_command("create_dvd", _cmd_create_dvd, ["amount"], 0, "Spawn DVD cube(s). Example: create_dvd 32", ["1"])
	Console.add_command("delete_dvd", _cmd_delete_dvd, ["amount"], 0, "Remove DVD cube(s). Example: delete_dvd 32", ["1"])

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
	for dvd in dvds:
		var mesh: MeshInstance3D = dvd["mesh_instance"]
		var vel: Vector3 = dvd["velocity"]
		var sz: float = mesh.mesh.size.x * 0.5

		var pos := mesh.position + vel * dvd_speed * delta
		var bounced := false

		if pos.x - sz <= -bounds.x:
			pos.x = -bounds.x + sz
			vel.x = abs(vel.x)
			bounced = true
		elif pos.x + sz >= bounds.x:
			pos.x = bounds.x - sz
			vel.x = -abs(vel.x)
			bounced = true

		if pos.y - sz <= -bounds.y:
			pos.y = -bounds.y + sz
			vel.y = abs(vel.y)
			bounced = true
		elif pos.y + sz >= bounds.y:
			pos.y = bounds.y - sz
			vel.y = -abs(vel.y)
			bounced = true

		if pos.z - sz <= -bounds.z:
			pos.z = -bounds.z + sz
			vel.z = abs(vel.z)
			bounced = true
		elif pos.z + sz >= bounds.z:
			pos.z = bounds.z - sz
			vel.z = -abs(vel.z)
			bounced = true

		if bounced:
			var new_color := Color(randf(), randf(), randf())
			dvd["color"] = new_color
			(mesh.material_override as StandardMaterial3D).albedo_color = new_color

		mesh.position = pos
		dvd["velocity"] = vel


# --- Console command callbacks ---

func _cmd_speed(value: String) -> void:
	var s := value.to_float()
	if s <= 0:
		Console.print_error("Speed must be a positive number.")
		return
	dvd_speed = s
	Console.print_line("All DVD speeds set to %s" % s)


func _cmd_size(value: String) -> void:
	var s := value.to_float()
	if s <= 0:
		Console.print_error("Size must be a positive number.")
		return
	dvd_size = s
	for dvd in dvds:
		var mesh: MeshInstance3D = dvd["mesh_instance"]
		(mesh.mesh as BoxMesh).size = Vector3.ONE * s
	Console.print_line("All DVD sizes set to %s" % s)


func _cmd_color(value: String) -> void:
	var c := Color.from_string(value, Color(-1, -1, -1))
	if c == Color(-1, -1, -1):
		Console.print_error("Unknown color '%s'. Try: red, green, blue, cyan, magenta, yellow, white, orange, pink, purple." % value)
		return
	for dvd in dvds:
		dvd["color"] = c
		var mesh: MeshInstance3D = dvd["mesh_instance"]
		(mesh.material_override as StandardMaterial3D).albedo_color = c
	Console.print_line("All DVD colors set to %s" % value)


func _cmd_angle(value: String) -> void:
	var a := value.to_float()
	dvd_angle_deg = a
	var rad := deg_to_rad(a)
	var vel := Vector3(cos(rad), sin(rad), 0.0).normalized()
	for dvd in dvds:
		dvd["velocity"] = vel
	Console.print_line("All DVD angles set to %s degrees" % a)


func _cmd_create_dvd(amount: String = "1") -> void:
	var count := int(amount)
	if count <= 0:
		Console.print_error("Amount must be a positive number.")
		return
	for i in count:
		dvds.append(_create_dvd_data())
	Console.print_line("Created %s DVD(s). Total: %s" % [count, dvds.size()])


func _cmd_delete_dvd(amount: String = "1") -> void:
	if dvds.is_empty():
		Console.print_error("No DVDs to remove.")
		return
	var count := mini(int(amount), dvds.size())
	if count <= 0:
		Console.print_error("Amount must be a positive number.")
		return
	for i in count:
		var dvd: Dictionary = dvds.pop_back()
		var mesh: MeshInstance3D = dvd["mesh_instance"]
		mesh.queue_free()
	Console.print_line("Removed %s DVD(s). Remaining: %s" % [count, dvds.size()])


func _on_quit_button_pressed() -> void:
	get_tree().quit()
