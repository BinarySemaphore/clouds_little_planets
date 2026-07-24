#[compute]
#version 450

#include "./godot_ubo.glslinc"
#include "./config_ubo.glslinc"
#include "./utils.glslinc"

layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

layout(set = 0, binding = 1) uniform sampler2D in_depth_sampler;

layout(rgba16f, set = 0, binding = 2) uniform image2D inout_image;

layout(r16f, set = 0, binding = 7) uniform readonly image2D in_depth_clouds;

layout(rgba16f, set = 0, binding = 8) uniform readonly image2D in_image_clouds;

layout(set = 0, binding = 3, std140) uniform readonly uniformBuffer {
	GDUBO data;
} scene;

layout(set = 0, binding = 4, std140) uniform readonly uniformConfig {
	CGUBO data;
} config;

float atmo_density(float altitude) {
	float alt_normal = altitude / config.data.atmo_alt;
	return clamp(exp(-config.data.density_falloff * alt_normal), 0.0, 1.0);
}

float alt_from_pos(vec3 pos) {
	vec3 rel_pos = pos - config.data.pos;
	return clamp(length(rel_pos) - config.data.radius, 0.0, config.data.atmo_alt);
}

vec4 color_through_atmo(vec3 start, vec3 dir, float dist, int samples, bool no_direct_light) {
	if (dist <= 0.0) return vec4(0.0);
	start *= rand_near_one(0.0001);
	float light_wrap = 0.05;
	float atmo_light_wrap = light_wrap;
	float star_fade = 1.0 - config.data.star_glow;

	vec4 color = vec4(0.0);

	float step_size = dist / float(samples - 1);
	float atmo_radius = config.data.radius + config.data.atmo_alt;
	float travel_dist = 0.0;
	float direct_light = 1.0;
	float total_density = 0.0;
	float start_altitude = alt_from_pos(start);
	float r_to_m_line = 0.6;
	float end_line = -0.3;

	// Direct light planet occlusion
	vec2 hit_planet;
	if(no_direct_light) {
		direct_light = 0.0;
	} else {
		hit_planet = sphere_intersect(start, dir, config.data.pos, config.data.radius);
		if (hit_planet.y > 0.0) {
			direct_light = 1.0 - smoothstep(0.0, light_wrap * config.data.radius, hit_planet.y);
		}
	}
	
	vec3 pos, rel_pos, planet_norm, to_light, sample_color;
	vec2 hit_atmo;
	float total_dist, altitude, altitude_normal, density, eng_from_light,
		eng_from_star, from_light, path_light, up_align, overhead_scatter,
		r1, r2, m1, m2;
	for (int i = 0; i < samples; i++) {
		pos = start + travel_dist * dir;
		rel_pos = pos - config.data.pos;
		altitude = length(rel_pos) - config.data.radius;
		if (altitude < -1.0) {
			travel_dist += step_size;
			continue;
		}
		altitude_normal = altitude / config.data.atmo_alt;
		to_light = normalize(config.data.light_pos - pos);
		density = exp(-altitude_normal * config.data.density_falloff);

		planet_norm = normalize(rel_pos);
		from_light = dot(planet_norm, to_light);
		path_light = dot(dir, to_light);
		up_align = dot(dir, planet_norm);
		overhead_scatter = clamp(
			0.5 * clamp(from_light, 0.0, 1.0)  // Positioning
			* clamp(up_align + 0.3, 0.0, 1.0)  // Apply up and horizon
			* smoothstep(config.data.atmo_alt * 1.5 / config.data.density_falloff, 0.0, start_altitude),  // Primary driven by camera altitude
			0.0, 1.0
		);

		total_density += density * step_size;
		total_density += (1.0 - density) * overhead_scatter;

		eng_from_star = 20.0 * direct_light * smoothstep(star_fade, 1.0, path_light);
		eng_from_light =
			clamp(from_light + atmo_light_wrap, 0.0, 1.0)
			+ eng_from_star;
		if (altitude < config.data.atmo_alt - config.data.light_pen) {
			float drown_out = smoothstep(0.0, config.data.light_pen, config.data.atmo_alt - config.data.light_pen - altitude);
			eng_from_light *= -1.0 * drown_out;
			eng_from_star *= -1.0 * drown_out;
		}

		// Reyleigh scatter
		// Primary
		r1 = smoothstep(r_to_m_line * 0.25, 1.0, from_light);
		r2 = 0.25 * clamp(abs(up_align) + 0.5, 0.0, 1.0)
					// Positioning
					* smoothstep(end_line * 0.5, r_to_m_line * 0.5, from_light);
		// Mie scatter
		// Primary
		m1 = 0.5 * travel_dist * travel_dist / atmo_radius
					* (1.0 - 1.0 * clamp(up_align, 0.0, 1.0))  // Upper cutoff
					* (1.0 - 4.0 * clamp(-up_align, 0.0, 1.0))  // Lower cutoff
					// Positioning
					* smoothstep(r_to_m_line, 0.0, from_light)
					* smoothstep(end_line, r_to_m_line * 0.5, from_light);
		// Solar
		m2 = eng_from_star * 10.0 * travel_dist / atmo_radius;

		sample_color = config.data.color_star * eng_from_light;
		sample_color -= config.data.rayleigh_coefs * (r1 + r2);
		sample_color -= config.data.mie_coefs * (m1 + m2);
		color.rgb += sample_color;

		travel_dist += step_size;
	}

	color.rgb = clamp(color.rgb / float(samples), vec3(0.0), vec3(5.0));
	color.a = 1.0 - exp(-total_density);

	return color;
}

void main() {
	ivec2 uv = ivec2(gl_GlobalInvocationID.xy);
	if (uv.x >= scene.data.viewport_size.x || uv.y >= scene.data.viewport_size.y) return;
	seed = rand_seed_2d(vec2(uv));

	vec2 screen_uv = get_screen_uv(uv, scene.data.viewport_size);

	float depth_planar = texture(in_depth_sampler, screen_uv).r;
	vec4 ndc = get_ndc(screen_uv, depth_planar);
	float depth_planar_linear = get_depth_linear(scene.data.inv_projection_matrix, ndc);
	vec3 cam_forward = get_cam_forward(scene.data.inv_view_matrix);
	vec3 cam_pos = get_cam_world_pos(scene.data.inv_view_matrix);
	vec3 dir = ray_screen(scene.data.inv_view_matrix, scene.data.inv_projection_matrix, screen_uv);
	float depth_lim = depth_planar_linear / dot(dir, cam_forward);
	vec4 color = imageLoad(inout_image, uv);
	// color = vec4(vec3(depth_lim), 1.0);

	bool is_valid = false;
	vec2 hit;
	vec3 start_pos = vec3(0.0);
	float atmo_travel_dist = 0.0;
	float max_travel_dist = 0.0;
	if (sphere_in_view(cam_pos, dir, config.data.pos, config.data.radius + config.data.atmo_alt, depth_lim)) {
		hit = sphere_intersect_prechecked(cam_pos, dir, config.data.pos, config.data.radius + config.data.atmo_alt);
		// Invalidate any distances beyond dist_limit when used
		if (config.data.dist_limit > 0.0 && hit.x > config.data.dist_limit) {
			hit.y = 0.0;
		}
		if (hit.y > 0.0 && hit.x <= depth_lim) {
			atmo_travel_dist = hit.y;
			start_pos = cam_pos + dir * hit.x;
			max_travel_dist = min(depth_lim - hit.x, hit.y);
			is_valid = true;
		}
	}

	if (is_valid) {
		if (config.data.atmo_enable) {
			vec4 atmo_color = color_through_atmo(start_pos, dir, max_travel_dist, 10, false);
			color.rgb = mix(color.rgb, atmo_color.rgb, atmo_color.a);
		}

		if (config.data.cloud_enable) {
			vec4 cloud_color = imageLoad(in_image_clouds, uv);
			color.rgb = mix(color.rgb, cloud_color.rgb, cloud_color.a);
			color.a = mix(color.a, 1.0, cloud_color.a);
		}
	}

	imageStore(inout_image, uv, color);
}
