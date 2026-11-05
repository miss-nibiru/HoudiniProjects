# Cinematic fluid splash

This is the existing 100-frame, 24 FPS dynamic-mesh VAT example from
`CinematicProject/Godot_VAT3-main/dynamicMeshTest`, reused as a stylized river
splash. The mesh, buffer, lookup PNG, HDR position/rotation/color textures, and
JSON are unchanged copies. Only their Godot resource paths and import identities
are local to this project. No Houdini simulation or water-frame export is needed.

The three falling jets and splash basin suit a brief splash more than a continuous
waterfall. The new material tints them to the river palette; it uses the existing
VAT library without changing that library or the river shader. The color texture
is retained because the library's dynamic-mesh branch requires color decoding,
even though the new fragment shader uses the river palette.

`water/FluidSplash` in `00_Scene/dragon_race.tscn` is positioned at
`(8.5, 0.91, 0.5)` with scale `0.14`, on the foreground river in the existing
camera's view. Its placement and material can be adjusted independently.

The existing `dragon_race.gd` passes `source_frame` to the effect. It starts at
frame 575 (the existing break event), plays the 100 source frames once through
frame 674, then hides. It fades in over source frames 1–6 and out over 88–100
to conceal the source clip's abrupt boundaries. It never loops or uses shader
`TIME`. Dynamic topology is sampled at whole frames by the existing VAT library;
fractional scrubbing is quantized there rather than interpolating incompatible
meshes. Pause, restart, speed changes, and scrubbing follow the original timeline.
The cinematic remains 24 FPS and ends at frame 800.

The original river, dragons, cloth, flags, ribbon, camera, and their animation
configuration are unchanged. Only three lines were added to the main controller
to forward its current frame.

## Validation

Use the existing checkout and a disposable project copy for validation because
Godot can rewrite tracked import/resource metadata:

```sh
mkdir -p /tmp/dragon-race-check
cp -a CinematicProject/_A2_Cinematic/. /tmp/dragon-race-check/
godot --headless --path /tmp/dragon-race-check --editor --import
godot --headless --path /tmp/dragon-race-check --script res://tests/fluid_splash_test.gd
godot --headless --path /tmp/dragon-race-check --quit-after 120
```

Require the test's PASS message, zero exit status, and no script/resource errors
in the logs; Godot can exit zero after an import error. Git LFS textures must be
materialized before import. The test checks all 800 frames of the original VAT
tracks and new splash, plus pause, speed, restart, and instance isolation.

Godot 4.6.3 was available for validation; the project declares 4.7. Software OpenGL
rendering was used to inspect the asset and placement with temporary review
lighting. The supplied scene has no light or WorldEnvironment, so its normal
runtime view is dark; no lighting or camera changes are included here. Review
final lighting, transparency, framing, and the splash's artistic fit in your
target Godot version with Forward+ before final export.
