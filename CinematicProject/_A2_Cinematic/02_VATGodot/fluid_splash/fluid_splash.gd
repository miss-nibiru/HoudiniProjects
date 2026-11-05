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
    var clip_frame := (frame - start_frame) * CLIP_FPS / CINEMATIC_FPS + 1.0
    visible = clip_frame >= 1.0 and clip_frame <= CLIP_FRAMES
    if material == null:
        return
    material.set_shader_parameter("_autoPlayback", false)
    material.set_shader_parameter("_displayFrame", clampf(clip_frame, 1.0, CLIP_FRAMES))
    # Hide the source clip's appearance and cutoff without looping its discontinuity.
    var fade_in := smoothstep(1.0, 6.0, clip_frame)
    var fade_out := 1.0 - smoothstep(88.0, CLIP_FRAMES, clip_frame)
    material.set_shader_parameter("effect_opacity", fade_in * fade_out if visible else 0.0)
