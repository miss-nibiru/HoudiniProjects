shader_type spatial;
render_mode cull_disabled, depth_prepass_alpha;

#define VAT3MODE_DYNAMICMESH
#define VAT_LOAD_COL_TEX
#include "res://VAT3_GodotEngine/VAT3_Wraper.gdshaderinc"

uniform vec4 water_dark : source_color = vec4(0.02, 0.23, 0.34, 1.0);
uniform vec4 water_light : source_color = vec4(0.09, 0.49, 0.56, 1.0);
uniform float effect_opacity : hint_range(0.0, 1.0) = 0.0;

void vertex() {
    Vat3_Vertex_Input inputs;
    inputs.vertexPosition = VERTEX;
    inputs.texCoord0 = UV;
    Vat3_Outputs outputs = ApplyVAT3_Deformation(inputs, GetVat3Inputs(inputs));
    VERTEX = outputs.outPosition.xyz;
    NORMAL = outputs.outNormal.xyz;
    TANGENT = outputs.outTangent;
}

void fragment() {
    float highlight = pow(1.0 - abs(dot(normalize(NORMAL), normalize(VIEW))), 2.0);
    ALBEDO = mix(water_dark.rgb, water_light.rgb, 0.35 + 0.65 * highlight);
    ROUGHNESS = 0.23;
    SPECULAR = 0.65;
    ALPHA = effect_opacity;
}
