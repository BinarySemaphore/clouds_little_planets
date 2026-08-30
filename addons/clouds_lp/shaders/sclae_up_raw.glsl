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

	vec4 cloud_depth_data = imageLoad(in_depth, ivec2(vec2(uv) * ratio));
	float cloud_depth_near = cloud_depth_data.r;
	float cloud_depth_far = cloud_depth_data.g;
	float cloud_sandwich = cloud_depth_data.b;

	ivec2 scaled_uv = ivec2(floor(vec2(uv) * ratio));

	vec4 out_color_image = vec4(0.0);

	// if (cloud_depth < native_depth) {
		// } else {
			out_color_image = imageLoad(in_image_far, scaled_uv);
		// }
	// }
	out_color_image = imageLoad(in_image_far, scaled_uv);
	if (cloud_sandwich >= 0.5) {
		float blend = clamp(inv_lerp(cloud_depth_near, cloud_depth_far, native_depth), 0.0, 1.0);
		vec4 near_color = imageLoad(in_image_near, scaled_uv);
		out_color_image = mix(near_color, out_color_image, blend);
	}
	// if (cloud_sandwich >= 0.5 && cloud_depth > native_depth * 1.1) {
	// 	vec4 near = imageLoad(in_image_near, scaled_uv);
	// 	out_color_image = near;// mix(near, out_color_image, out_color_image.a);
	// 	out_color_image = vec4(1.0, 0.0, 0.0, 1.0);
	// }


	imageStore(out_image, uv, out_color_image);
}
