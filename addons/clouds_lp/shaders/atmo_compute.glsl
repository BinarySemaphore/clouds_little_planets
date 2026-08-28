#[compute]
#version 450

#include "./includes/struct_ubo_godot.glslinc"
#include "./includes/struct_ubo_config.glslinc"
#include "./includes/utils.glslinc"

layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

layout(set = 0, binding = 1) uniform sampler2D in_depth_sampler;

layout(rgba16f, set = 0, binding = 2) uniform image2D inout_image;

layout(rgba16f, set = 0, binding = 7) uniform readonly image2D in_depth_clouds;

layout(rgba16f, set = 0, binding = 8) uniform readonly image2D in_image_clouds;

layout(set = 0, binding = 3, std140) uniform readonly uniformBuffer {
	GDUBO data;
} scene;

layout(set = 0, binding = 4, std140) uniform readonly uniformConfig {
	CGUBO data;
} config;

#include "./includes/atmo.glslinc"
#include "./includes/atmo_main.glslinc"
