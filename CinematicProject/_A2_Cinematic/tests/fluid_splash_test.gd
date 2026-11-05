extends SceneTree
## Run after import: godot --headless --path . --script res://tests/fluid_splash_test.gd

var failures: int = 0
var checks: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)


func _run() -> void:
	var scene = load("res://00_Scene/dragon_race.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	_check(scene.playing, "Original autoplay starts")
	scene.playing = false
	var splash = scene.get_node("water/FluidSplash")
	var river = scene.get_node("water/river/out_river_base")
	_check(river.get_surface_override_material(0).shader.resource_path ==
		"res://00_Scene/river.gdshader", "Original river shader remains assigned")
	_check(splash.material == splash.get_node("FluidMesh/Mesh").material_override,
		"Timeline drives the material used by the imported mesh")
	_check(not splash.material.get_shader_parameter("_autoPlayback"),
		"Fluid does not advance using shader TIME")
	_check(splash.material.get_shader_parameter("_frameCount") == 100.0,
		"Source clip keeps its 100-frame length")

	# Scrub every cinematic frame, including the collision and fluid boundaries.
	for frame in range(1, 801):
		scene.source_frame = float(frame)
		_check(scene.get_node("intact").visible == (frame < 575), "Intact visibility %d" % frame)
		_check(scene.get_node("destroyed").visible == (frame >= 575), "Destroyed visibility %d" % frame)
		_check(scene.get_node("winner").visible, "Winner visibility %d" % frame)
		_check(scene.intact_material.get_shader_parameter("_displayFrame") == minf(frame, 574.0),
			"Intact timeline %d" % frame)
		_check(scene.destroyed_material.get_shader_parameter("_displayFrame") == clampf(frame - 574.0, 1.0, 226.0),
			"Destroyed timeline %d" % frame)
		for material in [scene.winner_material, scene.ribbon_material]:
			_check(material.get_shader_parameter("_displayFrame") == float(frame),
				"Winner/ribbon timeline %d" % frame)
		_check(scene.flags_material.get_shader_parameter("_displayFrame") == fposmod(frame - 1.0, 90.0) + 1.0,
			"Flags timeline %d" % frame)
		_check(splash.visible == (frame >= 575 and frame <= 674), "Splash window %d" % frame)
		_check(splash.material.get_shader_parameter("_displayFrame") == clampf(frame - 574.0, 1.0, 100.0),
			"Fluid frame %d" % frame)
		var opacity: float = splash.material.get_shader_parameter("effect_opacity")
		if frame <= 575 or frame >= 674:
			_check(opacity == 0.0, "No fluid outside the faded clip %d" % frame)
		elif frame >= 580 and frame <= 662:
			_check(opacity == 1.0, "Fluid fully visible %d" % frame)
		else:
			_check(opacity > 0.0 and opacity < 1.0, "Fluid fades at clip edges %d" % frame)

	scene.source_frame = 600.5
	scene._process(1.0)
	_check(scene.source_frame == 600.5, "Pause freezes the cinematic")
	_check(splash.material.get_shader_parameter("_displayFrame") == 26.5, "Fractional scrub follows timeline")
	scene.playback_speed = 2.0
	scene.playing = true
	scene._process(1.0 / 24.0)
	scene.playing = false
	_check(is_equal_approx(scene.source_frame, 602.5), "Original playback speed retained")
	_check(is_equal_approx(splash.material.get_shader_parameter("_displayFrame"), 28.5), "Fluid follows playback speed")
	scene.source_frame = 799.0
	scene.playing = true
	scene._process(1.0)
	_check(scene.source_frame == 800.0 and not scene.playing, "Cinematic still stops at frame 800")
	var restart := InputEventKey.new()
	restart.pressed = true
	restart.keycode = KEY_R
	scene._unhandled_key_input(restart)
	_check(scene.source_frame == 1.0 and scene.playing and not splash.visible, "Restart resets fluid with cinematic")
	scene.playing = false

	var second_splash = load("res://02_VATGodot/fluid_splash/fluid_splash.tscn").instantiate()
	root.add_child(second_splash)
	second_splash.set_cinematic_frame(624.0)
	_check(second_splash.material != splash.material, "Fluid instances have independent materials")
	_check(splash.material.get_shader_parameter("_displayFrame") == 1.0, "Another instance cannot advance this clip")
	second_splash.free()
	scene.free()
	print("%s: %d checks, %d failures (800 frames, VAT regression, pause, speed, restart, instances)" %
		["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)
