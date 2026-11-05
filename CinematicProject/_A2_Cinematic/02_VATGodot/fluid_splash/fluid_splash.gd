@tool
extends Node3D
## Existing 100-frame fluid VAT, played once from the cinematic collision.
## No TIME-based playback: pause, restart and editor scrubbing use the same frame.

const CLIP_FRAMES: float = 100.0
const CLIP_FPS: float = 24.0
const CINEMATIC_FPS: float = 24.0

@export_range(1.0, 800.0, 1.0) var start_frame: float = 575.0
@export var material: ShaderMaterial


func _ready() -> void:
	# The imported child scene can localize its own material copy. Bind the
	# instance-local material that the cinematic actually drives.
	$FluidMesh/Mesh.material_override = material

func set_cinematic_frame(frame: float) -> void:
	visible = true

	if material == null:
		return

	var clip_frame := fposmod(frame - 1.0, CLIP_FRAMES) + 1.0

	material.set_shader_parameter("_autoPlayback", false)
	material.set_shader_parameter("_displayFrame", clip_frame)
	material.set_shader_parameter("effect_opacity", 1.0)
