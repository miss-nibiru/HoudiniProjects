
shader_type spatial;
render_mode cull_disabled;

uniform vec4 water_dark : source_color = vec4(0.02, 0.23, 0.34, 1.0);
uniform vec4 water_light : source_color = vec4(0.09, 0.49, 0.56, 1.0);

uniform vec2 river_center = vec2(0.0, 0.0);
uniform vec2 oval_radius = vec2(22.0, 15.0);

uniform float current_speed : hint_range(0.0, 4.0) = 0.65;
uniform float wave_height : hint_range(0.0, 0.3) = 0.04;

varying vec2 river_coordinates;

void vertex() {
    vec3 world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;

    river_coordinates = (world_pos.xz - river_center) / oval_radius;

    float angle = atan(river_coordinates.y, river_coordinates.x);
    float radius = length(river_coordinates);

    float wave =
        sin(angle * 14.0 - TIME * current_speed * 2.0 + radius * 14.0)
        + 0.4 * sin(angle * 29.0 - TIME * current_speed * 3.0 - radius * 21.0);

    VERTEX.y += wave * wave_height;
}

void fragment() {
    float angle = atan(river_coordinates.y, river_coordinates.x);
    float radius = length(river_coordinates);

    float ripple = sin(
        angle * 22.0 - TIME * current_speed * 2.0 + radius * 16.0
    ) * 0.5 + 0.5;

    float fine = sin(
        angle * 48.0 - TIME * current_speed * 3.0 - radius * 32.0
    ) * 0.5 + 0.5;

    float highlights = clamp(ripple * 0.7 + fine * 0.3, 0.0, 1.0);

    ALBEDO = mix(water_dark.rgb, water_light.rgb, highlights);
    ROUGHNESS = 0.23;
    SPECULAR = 0.65;
}