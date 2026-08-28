#[compute]
#version 450

#include "./includes/struct_ubo_godot.glslinc"
#include "./includes/struct_ubo_config.glslinc"
#include "./includes/utils.glslinc"

layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

layout(rgba16f, set = 0, binding = 5) uniform image2D inout_depth;

layout(rgba16f, set = 0, binding = 6) uniform writeonly image2D out_image;

layout(set = 0, binding = 3, std140) uniform readonly uniformBuffer {
	GDUBO data;
} scene;

layout(set = 0, binding = 4, std140) uniform readonly uniformConfig {
	CGUBO data;
} config;

layout(set = 0, binding = 10) uniform sampler2D alt_mask;
layout(set = 0, binding = 11) uniform sampler2D noise_mask;
layout(set = 0, binding = 12) uniform sampler3D noise_large;
layout(set = 0, binding = 13) uniform sampler3D noise_medium;
layout(set = 0, binding = 14) uniform sampler3D noise_small;
layout(set = 0, binding = 15) uniform sampler3D noise_wisp;

layout(push_constant, std430) uniform Params {
	vec2 size;
	float scale_down;
	float reserved;
} params;

#include "./includes/atmo.glslinc"
#include "./includes/cloud.glslinc"
