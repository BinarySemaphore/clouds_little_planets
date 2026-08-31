#[compute]
#version 450

#include "./includes/utils.glslinc"
#include "./includes/struct_ubo_godot.glslinc"

layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

layout(set = 0, binding = 1) uniform sampler2D in_depth_sampler;

layout(rgba16f, set = 0, binding = 5) uniform readonly image2D in_depth;

layout(rgba16f, set = 0, binding = 6) uniform readonly image2D in_image_near;

layout(rgba16f, set = 0, binding = 7) uniform readonly image2D in_image_far;

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
	float native_depth = native_depth(uv);

	vec2 p = (vec2(uv) + 0.5) * ratio - 0.5;
	vec2 f = fract(p);
	ivec2 scaled_uv = ivec2(floor(p));

	ivec2 uv_min = ivec2(0);
	ivec2 uv_max = ivec2(params.size) - ivec2(1);
	ivec2 scaled_uv_00 = clamp(scaled_uv, uv_min, uv_max);
	ivec2 scaled_uv_10 = clamp(scaled_uv + ivec2(1, 0), uv_min, uv_max);
	ivec2 scaled_uv_01 = clamp(scaled_uv + ivec2(0, 1), uv_min, uv_max);
	ivec2 scaled_uv_11 = clamp(scaled_uv + ivec2(1, 1), uv_min, uv_max);

	float blend;
	vec4 near_color;
	vec4 out_color_image_mix = vec4(0.0);
	vec4 a = imageLoad(in_image_far, scaled_uv_00);
	vec4 b = imageLoad(in_image_far, scaled_uv_10);
	vec4 c = imageLoad(in_image_far, scaled_uv_01);
	vec4 d = imageLoad(in_image_far, scaled_uv_11);

	vec4 cloud_dd_00 = imageLoad(in_depth, scaled_uv_00);
	vec4 cloud_dd_10 = imageLoad(in_depth, scaled_uv_10);
	vec4 cloud_dd_01 = imageLoad(in_depth, scaled_uv_01);
	vec4 cloud_dd_11 = imageLoad(in_depth, scaled_uv_11);

	if (cloud_dd_00.b >= 0.5) {
		blend = clamp(inv_lerp(cloud_dd_00.r, cloud_dd_00.g, native_depth), 0.0, 1.0);
		near_color = imageLoad(in_image_near, scaled_uv_00);
		a = mix(near_color, a, blend);
		/* DEBUG: Show blending on depth gradients */
		// a = vec4(1.0 - blend, blend, 0.0, 1.0);
	}
	if (cloud_dd_10.b >= 0.5) {
		blend = clamp(inv_lerp(cloud_dd_10.r, cloud_dd_10.g, native_depth), 0.0, 1.0);
		near_color = imageLoad(in_image_near, scaled_uv_10);
		b = mix(near_color, b, blend);
		/* DEBUG: Show blending on depth gradients */
		// b = vec4(1.0 - blend, blend, 0.0, 1.0);
	}
	if (cloud_dd_01.b >= 0.5) {
		blend = clamp(inv_lerp(cloud_dd_01.r, cloud_dd_01.g, native_depth), 0.0, 1.0);
		near_color = imageLoad(in_image_near, scaled_uv_01);
		c = mix(near_color, c, blend);
		/* DEBUG: Show blending on depth gradients */
		// c = vec4(1.0 - blend, blend, 0.0, 1.0);
	}
	if (cloud_dd_11.b >= 0.5) {
		blend = clamp(inv_lerp(cloud_dd_11.r, cloud_dd_11.g, native_depth), 0.0, 1.0);
		near_color = imageLoad(in_image_near, scaled_uv_11);
		d = mix(near_color, d, blend);
		/* DEBUG: Show blending on depth gradients */
		// d = vec4(1.0 - blend, blend, 0.0, 1.0);
	}
	out_color_image_mix = mix(mix(a, b, f.x), mix(c, d, f.x), f.y);

	imageStore(out_image, uv, out_color_image_mix);
}
