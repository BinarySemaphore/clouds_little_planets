#[compute]
#version 450

#include "./includes/struct_ubo_godot.glslinc"

layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

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

void main() {
	ivec2 uv = ivec2(gl_GlobalInvocationID.xy);
	if (uv.x >= scene.data.viewport_size.x || uv.y >= scene.data.viewport_size.y) return;

	vec2 ratio = params.size / scene.data.viewport_size;
	ivec2 scaled_uv = ivec2(floor(vec2(uv) * ratio));

	vec4 out_color_depth = imageLoad(in_depth, scaled_uv);
	vec4 out_color_image = imageLoad(in_image, scaled_uv);

	imageStore(out_depth, uv, out_color_depth);
	imageStore(out_image, uv, out_color_image);
}
