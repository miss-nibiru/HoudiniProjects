@tool
extends Node3D

const FPS: float = 24.0
const BREAK_FRAME: float = 575.0
const LAST_FRAME: float = 800.0

@export_category("Materials")
@export var intact_material: ShaderMaterial
@export var destroyed_material: ShaderMaterial
@export var winner_material: ShaderMaterial
@export var ribbon_material: ShaderMaterial
@export var flags_material: ShaderMaterial

@export_category("Exported JSON Files")
@export_file("*.json") var intact_json: String
@export_file("*.json") var destroyed_json: String
@export_file("*.json") var winner_json: String
@export_file("*.json") var ribbon_json: String
@export_file("*.json") var flags_json: String


@export_category("Timeline")
@export var autoplay: bool = true
@export_range(0.05, 2.0, 0.05) var playback_speed: float = 1.0

@export_range(1.0, 800.0, 0.01) var source_frame: float = 1.0:
	set(value):
		source_frame = clampf(value, 1.0, LAST_FRAME)
		if is_node_ready():
			_apply_frame()

@export var reload_vat_data: bool = false:
	set(value):
		reload_vat_data = false
		if value and is_node_ready():
			_setup_vat()

var playing: bool = false


func _ready() -> void:
	_setup_vat()

	if not Engine.is_editor_hint():
		source_frame = 1.0
		playing = autoplay


func _process(delta: float) -> void:
	if Engine.is_editor_hint() or not playing:
		return

	source_frame += delta * FPS * playback_speed

	if source_frame >= LAST_FRAME:
		playing = false


func _setup_vat() -> void:
	_configure_clip("intact", intact_material, intact_json, 574.0, false)
	_configure_clip("destroyed", destroyed_material, destroyed_json, 226.0, true)
	_configure_clip("winner", winner_material, winner_json, 800.0, false)
	_configure_clip("finish_ribbon", ribbon_material, ribbon_json, 800.0, false)
	_configure_clip("flags", flags_material, flags_json, 90.0, false)
	_apply_frame()


func _configure_clip(
	container_name: String,
	material: ShaderMaterial,
	json_path: String,
	frame_count: float,
	rigid: bool
) -> void:
	var container: Node = get_node_or_null(container_name)

	if container == null:
		push_error("Missing scene node: " + container_name)
		return

	if material == null or json_path.is_empty():
		return

	if not FileAccess.file_exists(json_path):
		push_error("Cannot find VAT JSON: " + json_path)
		return

	var parsed: Variant = JSON.parse_string(
		FileAccess.get_file_as_string(json_path)
	)

	if not parsed is Array:
		push_error("Expected an array in VAT JSON: " + json_path)
		return

	var entries: Array = parsed
	if entries.is_empty() or not entries[0] is Dictionary:
		push_error("VAT JSON has no metadata: " + json_path)
		return

	var data: Dictionary = entries[0]

	var bounds_min := Vector3(
		float(data.get("Bound Min X", 0.0)),
		float(data.get("Bound Min Y", 0.0)),
		float(data.get("Bound Min Z", 0.0))
	)

	var bounds_max := Vector3(
		float(data.get("Bound Max X", 0.0)),
		float(data.get("Bound Max Y", 0.0)),
		float(data.get("Bound Max Z", 0.0))
	)

	material.set_shader_parameter("_boundMin", bounds_min)
	material.set_shader_parameter("_boundMax", bounds_max)
	material.set_shader_parameter(
		"_houdiniFPS", float(data.get("Houdini FPS", FPS))
	)
	material.set_shader_parameter("_frameCount", frame_count)
	material.set_shader_parameter("_isTexHdr", true)
	material.set_shader_parameter("_autoPlayback", false)
	material.set_shader_parameter("_playbackSpeed", 1.0)
	material.set_shader_parameter("_gameTimeAtFirstFrame", 0.0)
	material.set_shader_parameter("_interpolate", true)
	material.set_shader_parameter("_surfaceNormals", false)

	if rigid:
		material.set_shader_parameter("_globalPscaleMul", 1.0)
		material.set_shader_parameter("_pscaleAreInPosA", false)
		material.set_shader_parameter("_stretchByVel", false)
		material.set_shader_parameter("_stretchByVelAmount", 0.0)
		material.set_shader_parameter("_animateFirstFrame", false)
		material.set_shader_parameter("_interpolateCol", false)

	_assign_material(container, material)


func _assign_material(node: Node, material: ShaderMaterial) -> void:
	if node is MeshInstance3D:
		var mesh_instance := node as MeshInstance3D
		mesh_instance.material_override = material

		# Include the moving geometry in the visibility bounds.
		mesh_instance.custom_aabb = AABB(
			Vector3(-100.0, -100.0, -100.0),
			Vector3(200.0, 200.0, 200.0)
		)

	for child in node.get_children():
		_assign_material(child, material)


func _apply_frame() -> void:
	var broken: bool = source_frame >= BREAK_FRAME
	var intact: Node3D = get_node_or_null("intact") as Node3D
	var destroyed: Node3D = get_node_or_null("destroyed") as Node3D
	var winner: Node3D = get_node_or_null("winner") as Node3D
	if intact != null:
		intact.visible = not broken
	if destroyed != null:
		destroyed.visible = broken
	if winner != null:
		winner.visible = true
	if intact_material != null:
		intact_material.set_shader_parameter(
			"_displayFrame", clampf(source_frame, 1.0, 574.0)
		)
	if destroyed_material != null:
		destroyed_material.set_shader_parameter(
			"_displayFrame",
			clampf(source_frame - BREAK_FRAME + 1.0, 1.0, 226.0)
		)
	if winner_material != null:
		winner_material.set_shader_parameter(
			"_displayFrame", source_frame
		)
	if ribbon_material != null:
		ribbon_material.set_shader_parameter("_displayFrame", source_frame)
	if flags_material != null:
		flags_material.set_shader_parameter( "_displayFrame", fposmod(source_frame - 1.0, 90.0) + 1.0)


func _unhandled_key_input(event: InputEvent) -> void:
	if Engine.is_editor_hint():
		return

	if event is InputEventKey:
		if not event.pressed or event.echo:
			return

		if event.keycode == KEY_SPACE:
			playing = not playing
		elif event.keycode == KEY_R:
			source_frame = 1.0
			playing = true
