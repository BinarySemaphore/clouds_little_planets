#[compute]
#version 450

#include "./includes/struct_ubo_godot.glslinc"

layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

layout(r16f, set = 0, binding = 5) uniform readonly image2D in_depth;

layout(rgba16f, set = 0, binding = 6) uniform readonly image2D in_image;

layout(r16f, set = 0, binding = 7) uniform writeonly image2D out_depth;

layout(rgba16f, set = 0, binding = 8) uniform writeonly image2D out_image;

layout(set = 0, binding = 3, std140) uniform readonly uniformBuffer {
	GDUBO data;
} scene;

layout(push_constant, std430) uniform readonly Params {
	vec2 size;
	float scale_down;
	float reserved;
} params;

void main() {
	ivec2 uv = ivec2(gl_GlobalInvocationID.xy);
	if (uv.x >= scene.data.viewport_size.x || uv.y >= scene.data.viewport_size.y) return;

	vec2 p = (vec2(uv) + 0.5) / params.scale_down - 0.5;
	vec2 f = fract(p);
	ivec2 scaled_uv = ivec2(floor(p));
	ivec2 uv_min = ivec2(0);
	ivec2 uv_max = ivec2(params.size) - ivec2(1);
	ivec2 scaled_uv_00 = clamp(scaled_uv, uv_min, uv_max);
	ivec2 scaled_uv_10 = clamp(scaled_uv + ivec2(1, 0), uv_min, uv_max);
	ivec2 scaled_uv_01 = clamp(scaled_uv + ivec2(0, 1), uv_min, uv_max);
	ivec2 scaled_uv_11 = clamp(scaled_uv + ivec2(1, 1), uv_min, uv_max);
	
	vec4 a = imageLoad(in_depth, scaled_uv_00);
	vec4 b = imageLoad(in_depth, scaled_uv_10);
	vec4 c = imageLoad(in_depth, scaled_uv_01);
	vec4 d = imageLoad(in_depth, scaled_uv_11);
	vec4 smoothed = mix(mix(a, b, f.x), mix(c, d, f.x), f.y);

	imageStore(out_depth, uv, smoothed);

	a = imageLoad(in_image, scaled_uv_00);
	b = imageLoad(in_image, scaled_uv_10);
	c = imageLoad(in_image, scaled_uv_01);
	d = imageLoad(in_image, scaled_uv_11);
	smoothed = mix(mix(a, b, f.x), mix(c, d, f.x), f.y);

	imageStore(out_image, uv, smoothed);
}
