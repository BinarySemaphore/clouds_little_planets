#[compute]
#version 450

#include "./includes/utils.glslinc"
#include "./includes/struct_ubo_godot.glslinc"

layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

layout(set = 0, binding = 1) uniform sampler2D in_depth_sampler;

layout(rgba16f, set = 0, binding = 5) uniform readonly image2D in_depth;

layout(rgba16f, set = 0, binding = 6) uniform readonly image2D in_image;

layout(rgba16f, set = 0, binding = 7) uniform writeonly image2D out_depth;

layout(rgba16f, set = 0, binding = 8) uniform writeonly image2D out_image;

layout(set = 0, binding = 3, std140) uniform readonly uniformBuffer {
	GDUBO data;
} scene;

layout(push_constant, std430) uniform readonly Params {
	vec2 size;
	float scale_down;
	float reserved;
} params;

float native_depth(ivec2 uv) {
	vec2 screen_uv = get_screen_uv(uv, scene.data.viewport_size);
	float depth_planar = texture(in_depth_sampler, screen_uv).r;
	vec4 ndc = get_ndc(screen_uv, depth_planar);
	float depth_planar_linear = get_depth_linear(scene.data.inv_projection_matrix, ndc);
	vec3 cam_forward = get_cam_forward(scene.data.inv_view_matrix);
	vec3 dir = ray_screen(scene.data.inv_view_matrix, scene.data.inv_projection_matrix, screen_uv);
	return depth_planar_linear / dot(dir, cam_forward);
}

void main() {
	ivec2 uv = ivec2(gl_GlobalInvocationID.xy);
	if (uv.x >= scene.data.viewport_size.x || uv.y >= scene.data.viewport_size.y) return;


	vec2 ratio = params.size / scene.data.viewport_size;
	vec2 p = (vec2(uv) + 0.5) * ratio - 0.5;
	vec2 f = fract(p);
	ivec2 scaled_uv = ivec2(floor(p));

	ivec2 uv_min = ivec2(0);
	ivec2 uv_max = ivec2(params.size) - ivec2(1);
	ivec2 scaled_uv_00 = clamp(scaled_uv, uv_min, uv_max);
	ivec2 scaled_uv_10 = clamp(scaled_uv + ivec2(1, 0), uv_min, uv_max);
	ivec2 scaled_uv_01 = clamp(scaled_uv + ivec2(0, 1), uv_min, uv_max);
	ivec2 scaled_uv_11 = clamp(scaled_uv + ivec2(1, 1), uv_min, uv_max);

	vec4 a = imageLoad(in_image, scaled_uv_00);
	vec4 b = imageLoad(in_image, scaled_uv_10);
	vec4 c = imageLoad(in_image, scaled_uv_01);
	vec4 d = imageLoad(in_image, scaled_uv_11);
	vec4 lrd_a = imageLoad(in_depth, scaled_uv_00);
	vec4 lrd_b = imageLoad(in_depth, scaled_uv_10);
	vec4 lrd_c = imageLoad(in_depth, scaled_uv_01);
	vec4 lrd_d = imageLoad(in_depth, scaled_uv_11);
	// float hr_depth = native_depth(uv);

	// // Standard spatial bilinear weights
	// float w00_spatial = (1.0 - f.x) * (1.0 - f.y);
	// float w10_spatial = f.x         * (1.0 - f.y);
	// float w01_spatial = (1.0 - f.x) * f.y;
	// float w11_spatial = f.x         * f.y;

	// // Depth similarity tolerance scale (tweak based on scene depth range/units)
	// const float DEPTH_SIGMA = scene.data.z_far; 

	// // Compute depth similarity weights based on Near Depth (R channel)
	// float w00_depth = exp(-pow(abs(hr_depth - lrd_a.r * scene.data.z_far) / DEPTH_SIGMA, 2.0));
	// float w10_depth = exp(-pow(abs(hr_depth - lrd_b.r * scene.data.z_far) / DEPTH_SIGMA, 2.0));
	// float w01_depth = exp(-pow(abs(hr_depth - lrd_c.r * scene.data.z_far) / DEPTH_SIGMA, 2.0));
	// float w11_depth = exp(-pow(abs(hr_depth - lrd_d.r * scene.data.z_far) / DEPTH_SIGMA, 2.0));

	// // Combined non-normalized weights
	// float w00 = w00_spatial * w00_depth;
	// float w10 = w10_spatial * w10_depth;
	// float w01 = w01_spatial * w01_depth;
	// float w11 = w11_spatial * w11_depth;


	// // float hr_depth = native_depth(uv);
	// // float ab_bias = ;
	// // float cd_bias = ;
	// // float lrd_ab = mix(lrd_a, lrd_b, ab_bias);
	// // float lrd_cd = mix(lrd_c, lrd_d, cd_bias);
	// // float v_bias = ;

	// float total_w = w00 + w10 + w01 + w11;

	// // Fallback to standard bilinear weights if depth difference rejects all taps
	// if (total_w < 1e-5) {
	// w00 = w00_spatial;
	// w10 = w10_spatial;
	// w01 = w01_spatial;
	// w11 = w11_spatial;
	// total_w = 1.0;
	// }

	// // Normalized weights for the 4 taps
	// float n00 = w00 / total_w;
	// float n10 = w10 / total_w;
	// float n01 = w01 / total_w;
	// float n11 = w11 / total_w;

	// // Convert 4 normalized weights into horizontal and vertical mix factors:
	// // Top row mix ratio (between A and B)
	// float ab_bias = (n00 + n10 > 1e-5) ? (n10 / (n00 + n10)) : f.x;

	// // Bottom row mix ratio (between C and D)
	// float cd_bias = (n01 + n11 > 1e-5) ? (n11 / (n01 + n11)) : f.x;

	// // Vertical mix ratio (between Top row and Bottom row)
	// float v_bias = n01 + n11;

	// vec4 out_color_image_mix = mix(mix(a, b, ab_bias), mix(c, d, cd_bias), v_bias);
	vec4 out_color_image_mix = mix(mix(a, b, f.x), mix(c, d, f.x), f.y);

	imageStore(out_image, uv, out_color_image_mix);

	vec4 out_color_depth_raw = imageLoad(in_depth, ivec2(vec2(uv) * ratio));
	// a = imageLoad(in_depth, scaled_uv_00);
	// b = imageLoad(in_depth, scaled_uv_10);
	// c = imageLoad(in_depth, scaled_uv_01);
	// d = imageLoad(in_depth, scaled_uv_11);
	vec4 out_color_depth_mix = vec4(out_color_depth_raw.r, mix(mix(lrd_a, lrd_b, f.x), mix(lrd_c, lrd_d, f.x), f.y).gba);
	// Retain near depth min hard edge (prevents full empty mixing behind edges)
	//out_color_depth_mix.r = min(out_color_depth_mix.r, out_color_depth.r);
	// out_color_depth_mix.g = max(out_color_depth_mix.g, out_color_depth.g);
	// out_color_depth.r = min(out_color_depth.r, native_depth(uv));

	imageStore(out_depth, uv, out_color_depth_mix);
}
