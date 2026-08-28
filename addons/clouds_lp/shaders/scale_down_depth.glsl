#[compute]
#version 450

#include "./includes/struct_ubo_godot.glslinc"
#include "./includes/utils.glslinc"

layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

layout(set = 0, binding = 1) uniform sampler2D in_depth_sampler;

layout(rgba16f, binding = 5) uniform writeonly image2D out_depth;

layout(set = 0, binding = 3, std140) uniform readonly uniformBuffer {
	GDUBO data;
} scene;

layout(push_constant, std430) uniform readonly Params {
	vec2 new_size;
	float scale_down;
	float reserved;
} params;

void main() {
	ivec2 out_uv = ivec2(gl_GlobalInvocationID.xy);
	if (out_uv.x >= params.new_size.x || out_uv.y >= params.new_size.y) return;

	vec2 ratio = scene.data.viewport_size / params.new_size;
	ivec2 r_min = ivec2(floor(vec2(out_uv) * ratio));
	ivec2 r_max = ivec2(floor(vec2(out_uv + 1) * ratio));


	// Get min/max depths for each group of native-res pixels
	// Low-res vol march can provide a near and far result when min/max depth
	// disagree, allowing for "sandwiching" around geometry edges during
	// final compositing. Otherwise there are difficult to resolve artifacts
	// around the geometry edges.
	float min_depth = MAX_DIST;
	float max_depth = 0.0;
	vec4 ndc;
	vec2 fs_screen_uv;
	float depth, lin_depth;
	for (int x = r_min.x; x < r_max.x; x++) {
		for(int y = r_min.y; y < r_max.y; y++) {
			fs_screen_uv = get_screen_uv(ivec2(x, y), scene.data.viewport_size);
			depth = texture(in_depth_sampler, fs_screen_uv).r;
			ndc = get_ndc(fs_screen_uv, depth);
			lin_depth = get_depth_linear(scene.data.inv_projection_matrix, ndc);
			max_depth = max(max_depth, lin_depth);
			min_depth = min(min_depth, lin_depth);
		}
	}

	imageStore(out_depth, out_uv, vec4(min_depth, max_depth, 0.0, 0.0));
}
