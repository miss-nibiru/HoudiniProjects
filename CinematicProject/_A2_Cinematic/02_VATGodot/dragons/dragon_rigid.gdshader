shader_type spatial;
render_mode cull_disabled;

#define VAT3MODE_RIGIDBODY
#define VAT_LOAD_COL_TEX

#include "res://VAT3_GodotEngine/VAT3_Wraper.gdshaderinc"

uniform vec4 base_color : source_color = vec4(0.2, 0.65, 1.0, 1.0);
uniform bool use_base_texture = false;
uniform sampler2D base_texture : source_color;

void vertex() {
	Vat3_Vertex_Input inputs;
	inputs.vertexPosition = VERTEX;
	inputs.texCoord0 = UV;
	inputs.texCoord1 = UV2;

	#if defined(VAT3MODE_RIGIDBODY)
		inputs.vertexNormal = NORMAL;
		inputs.vertexTangent = TANGENT;
		inputs.texCoord2 = CUSTOM0.xy;
		inputs.texCoord3 = CUSTOM0.zw;
	#endif

	Vat3_NonTexInputs settings = GetVat3Inputs(inputs);
	Vat3_Outputs result = ApplyVAT3_Deformation(inputs, settings);

	VERTEX = result.outPosition;
	NORMAL = result.outNormal;
	TANGENT = result.outTangent;
	UV = result.surfaceUv;
}

void fragment() {
	vec3 colour = base_color.rgb;

	if (use_base_texture) {
		colour *= texture(base_texture, UV).rgb;
	}

	ALBEDO = colour;
	ROUGHNESS = 0.45;
}