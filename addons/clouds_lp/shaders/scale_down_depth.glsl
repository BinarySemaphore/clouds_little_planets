#[compute]
#version 450

#include "./godot_ubo.glslinc"
#include "./utils.glslinc"

layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

layout(set = 0, binding = 1) uniform sampler2D in_depth_sampler;

layout(r16f, binding = 5) uniform writeonly image2D out_depth;

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

	int range = int(params.scale_down);
	float area_range = params.scale_down * params.scale_down;
	ivec2 fs_uv = out_uv * range;
	
	vec4 ndc;
	vec2 fs_screen_uv;
	float depth;
	float accum_depth = 0.0;
	for (int x = 0; x < range; x++) {
		for(int y = 0; y < range; y++) {
			fs_screen_uv = get_screen_uv(fs_uv + ivec2(x, y), scene.data.viewport_size);
			depth = texture(in_depth_sampler, fs_screen_uv).r;
			ndc = get_ndc(fs_screen_uv, depth);
			accum_depth += get_depth_linear(scene.data.inv_projection_matrix, ndc);
		}
	}
	
	accum_depth /= area_range;
	imageStore(out_depth, out_uv, vec4(accum_depth, 0.0, 0.0, 0.0));
}
