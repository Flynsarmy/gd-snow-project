shader_type spatial;

uniform sampler2D snow_albedo : source_color;
uniform sampler2D snow_normal : hint_normal;
uniform sampler2D snow_roughness : hint_roughness_r;
uniform sampler2D dirt_albedo : source_color;
uniform sampler2D dirt_normal : hint_normal;
uniform sampler2D dirt_roughness : hint_roughness_r;
uniform sampler2D displacement_grit : source_color;
uniform sampler2D displacement_gradient : source_color, repeat_disable;
uniform sampler2D dynamic_snow_mask;
uniform float uv_scale = 1.0;
uniform float snow_height = 1.0;

// Sobel filter to fix displaced normals
// Resolution of your dynamic_snow_mask
uniform float mask_resolution = 128.;
// Multiplier to adjust the steepness/strength of the generated shadows
uniform float normal_strength = 1.0;


float overlay(float a, float b) {
	if (a < .5) {
		return a * b * 2.;
	} else {
		return 1. - 2. * (1. - a) * (1. - b);
	}
}

// Samples the height map in a 3x3 grid to calculate the gradient slope
vec3 get_sobel_normal(sampler2D tex, vec2 uv, float v_color_r) {
    float offset = 1.0 / mask_resolution;

    // We include snow_height and vertex color so the normal matches the physical displacement exactly
    float h_factor = v_color_r * snow_height * normal_strength;

    float h00 = texture(tex, uv + vec2(-offset, -offset)).r * h_factor;
    float h10 = texture(tex, uv + vec2(0.0, -offset)).r * h_factor;
    float h20 = texture(tex, uv + vec2(offset, -offset)).r * h_factor;

    float h01 = texture(tex, uv + vec2(-offset, 0.0)).r * h_factor;
    float h21 = texture(tex, uv + vec2(offset, 0.0)).r * h_factor;

    float h02 = texture(tex, uv + vec2(-offset, offset)).r * h_factor;
    float h12 = texture(tex, uv + vec2(0.0, offset)).r * h_factor;
    float h22 = texture(tex, uv + vec2(offset, offset)).r * h_factor;

    // Sobel math for X and Y gradients
    float dX = (h20 + 2.0 * h21 + h22) - (h00 + 2.0 * h01 + h02);
    float dY = (h00 + 2.0 * h10 + h20) - (h02 + 2.0 * h12 + h22);

    // Construct the tangent space normal.
    // Z is 1.0 representing 'up' (facing outward).
    return normalize(vec3(-dX, -dY, 1.0));
}

void vertex() {
	vec2 uv = UV * uv_scale;
	float snow_mask = COLOR.r;
	snow_mask *= texture(dynamic_snow_mask, uv).r;

	VERTEX.y += snow_mask * snow_height;
}

void fragment() {
	vec2 uv = UV * uv_scale;
	vec3 snow_a = texture(snow_albedo, uv).rgb;
	vec3 snow_n = texture(snow_normal, uv).rgb;
	float snow_r = texture(snow_roughness, uv).r;
	vec3 dirt_a = texture(dirt_albedo, uv).rgb;
	vec3 dirt_n = texture(dirt_normal, uv).rgb;
	float dirt_r = texture(dirt_roughness, uv).r;

	float snow_mask = COLOR.r;
	float displacement = texture(dynamic_snow_mask, uv).r;
	if (displacement < .2) {
		displacement = overlay(texture(displacement_gradient, uv).r, texture(displacement_grit, uv).r);
	}
	snow_mask *= displacement;

	// Calculate macro normal from the dynamic mask using Sobel
    vec3 macro_normal = get_sobel_normal(dynamic_snow_mask, uv, COLOR.r);
    // Mix the detail texture normal maps (these are packed in 0 to 1 space)
    vec3 mixed_detail_n = mix(dirt_n, snow_n, snow_mask);
    // Unpack the detail normal from [0, 1] to [-1, 1] range so we can do math with it
    vec3 unpacked_detail_n = mixed_detail_n * 2.0 - 1.0;
    // Blend the Macro normal with the Detail normal (using UDN Blending)
    vec3 blended_normal = normalize(vec3(macro_normal.xy + unpacked_detail_n.xy, macro_normal.z));
	// Pack back to [0, 1] space
	vec3 calculated_normal = blended_normal * 0.5 + 0.5;

	ALBEDO = mix(dirt_a, snow_a, snow_mask);
	NORMAL_MAP = calculated_normal;
	ROUGHNESS = mix(dirt_r, snow_r, snow_mask);
}
