#[compute]
#version 450

#include "./godot_ubo.glslinc"
#include "./config_ubo.glslinc"
#include "./utils.glslinc"

layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

layout(r16f, set = 0, binding = 5) uniform image2D inout_depth;

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

float atmo_density(float altitude) {
	float alt_normal = altitude / config.data.atmo_alt;
	return clamp(exp(-config.data.density_falloff * alt_normal), 0.0, 1.0);
}

float alt_from_pos(vec3 pos) {
	vec3 rel_pos = pos - config.data.pos;
	if (config.data.flat_world) {
		return clamp(rel_pos.y - config.data.radius, 0.0, config.data.atmo_alt);
	}
	return clamp(length(rel_pos) - config.data.radius, 0.0, config.data.atmo_alt);
}

vec4 color_through_atmo(vec3 start, vec3 dir, float dist, int samples, bool no_direct_light) {
	if (dist <= 0.0) return vec4(0.0);
	start *= rand_near_one(0.0001);
	float light_wrap = 0.05;
	float atmo_light_wrap = light_wrap;
	float star_fade = 1.0 - config.data.star_glow;

	vec4 color = vec4(0.0);
	vec3 up = vec3(0.0, 1.0, 0.0);  // Used for flat_world

	float step_size = dist / float(samples - 1);
	float atmo_radius = config.data.radius + config.data.atmo_alt;
	if (config.data.flat_world) {
		atmo_radius = 100.0 * config.data.cl_global_scale + config.data.atmo_alt;
	}
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
		float wrap_lim = light_wrap * config.data.radius;
		if (config.data.flat_world) {
			wrap_lim = light_wrap;
			hit_planet = vec2(0.0);
			hit_planet.y = plane_intersect(start, dir, up * config.data.radius, up);
		} else {
			hit_planet = sphere_intersect(start, dir, config.data.pos, config.data.radius);
		}
		if (hit_planet.y > 0.0) {
			direct_light = 1.0 - smoothstep(0.0, wrap_lim, hit_planet.y);
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
		if (config.data.flat_world) {
			altitude = rel_pos.y - config.data.radius;
		} else {
			altitude = length(rel_pos) - config.data.radius;
		}
		if (altitude < -1.0) {
			travel_dist += step_size;
			continue;
		}
		altitude_normal = altitude / config.data.atmo_alt;
		to_light = normalize(config.data.light_pos - pos);
		density = exp(-altitude_normal * config.data.density_falloff);

		if (config.data.flat_world) {
			planet_norm = up;
		} else {
			planet_norm = normalize(rel_pos);
		}
		from_light = dot(planet_norm, to_light);
		path_light = dot(dir, to_light);
		up_align = dot(dir, planet_norm);
		overhead_scatter = clamp(
			0.5 * clamp(from_light, 0.0, 1.0)  // Positioning
			* clamp(up_align + 0.3, 0.0, 1.0)  // Apply up and horizon
			* smoothstep(config.data.atmo_alt * 1.5 / config.data.density_falloff, 0.0, start_altitude),  // Primary driven by camera altitude
			0.0, 1.0
		);

		total_density += density * step_size / config.data.cl_global_scale;
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
		if (config.data.flat_world) {
			m1 = (1.0 - pow(abs(from_light), 0.25))
				* clamp(travel_dist * 20.0 / atmo_radius, 0.0, 1.0)
				// Cutoffs (upper/lower)
				* (1.0 - clamp(up_align + 0.5, 0.0, 1.0))
				* (1.0 - 4.0 * clamp(-up_align, 0.0, 1.0))
				// Positioning
				* smoothstep(r_to_m_line, 0.0, from_light)
				* smoothstep(end_line, r_to_m_line * 0.25, from_light);
		} else {
			m1 = 0.5 * clamp(travel_dist * travel_dist/ atmo_radius, 0.0, 1.0)
				// Cutoffs (upper/lower)
				* (1.0 - clamp(up_align, 0.0, 1.0))
				* (1.0 - 4.0 * clamp(-up_align, 0.0, 1.0))
				// Positioning
				* smoothstep(r_to_m_line, 0.0, from_light)
				* smoothstep(end_line, r_to_m_line * 0.5, from_light);
		}
		// Solar
		//m1 = 1.0 - pow(abs(from_light), 0.2);
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

vec2 lat_long_from_pos_to_uv(vec3 pos) {
	if (config.data.flat_world) {
		return vec2(pos.x, pos.z) / (100.0 * config.data.cl_global_scale);
	}
	vec3 norm_pos = normalize(pos);
	float lat_angle = asin(-norm_pos.y / 1.0);
	float long_angle = atan(norm_pos.x, norm_pos.z);

	return vec2(
		long_angle / TAU + 0.5,
		(lat_angle / PI_HALF + 1.0) * 0.5
	);
}

bool light_occluded_by_planet(vec3 pos, vec3 light_dir) {
	if (sphere_in_view(pos, light_dir, config.data.pos, config.data.radius, 1000.0)) {
		vec2 hit = sphere_intersect_prechecked(pos, light_dir, config.data.pos, config.data.radius);
		return hit.y > 0.0;
	}
	return false;
}

/* For total density */
float powder_beers_lumin(float density, float dl, float ds) {
	float powder = 1.0 - exp(-ds * density);
	float beers = exp(-dl * density);
	return clamp(beers * powder * 5.0, 0.0, 1.0);
}

/* For descrete density sample accumulation */
float powder_beers_lumin_desc(float density, float dl, float ds) {
	float powder = 1.0 - (1.0 / ds) * exp(-ds * density);
	float beers = (1.0 / dl) * exp(-dl * density);
	return beers * powder;
}

float cloud_density_at_pos(vec3 pos) {
	float alt_u = pow(alt_from_pos(pos) / config.data.atmo_alt, 0.5);
	vec4 alt_mask = texture(alt_mask, vec2(alt_u, 0.0));
	if (alt_mask.r <= 0.0) return 0.0;

	pos -= config.data.pos;

	float g_scale_sq = alt_mask.g * alt_mask.g;
	float modified_global_scale = config.data.cl_global_scale * g_scale_sq;

	float l_scale = config.data.cl_scale.x * modified_global_scale;
	float m_scale = config.data.cl_scale.y * modified_global_scale;
	float s_scale = config.data.cl_scale.z * modified_global_scale;
	float curl_scale = config.data.cl_wisp_scale * modified_global_scale;

	vec2 latlong_pos = lat_long_from_pos_to_uv(pos) + config.data.cl_mask_offset + vec2(5.0) * alt_mask.b;
	float d_xl = smoothstep(config.data.cl_threshold.x, config.data.cl_threshold.y,
		texture(noise_mask, latlong_pos / g_scale_sq).r);
	
	float mask_and_alt_density = alt_mask.r * d_xl;
	pos += config.data.cl_offset;

	float d_l = smoothstep(config.data.cl_threshold.x, config.data.cl_threshold.y,
		texture(noise_large, pos / l_scale)).r;
	
	float wisp = clamp(1.0 - mask_and_alt_density * d_l * 2.0, 0.0, 1.0) * modified_global_scale * config.data.cl_wisp;
	pos += (texture(noise_wisp, pos / curl_scale).xyz * 2.0 - 1.0) * wisp;

	// d_l = smoothstep(config.data.cl_threshold.x, config.data.cl_threshold.y,
	// 	texture(noise_large, pos / l_scale)).r;
	float d_m = smoothstep(config.data.cl_threshold.x, config.data.cl_threshold.y,
		texture(noise_medium, pos / m_scale)).r;
	float d_s = smoothstep(config.data.cl_threshold.x, config.data.cl_threshold.y,
		texture(noise_small, pos / s_scale)).r;

	float density = mix(d_l * d_m, d_l, config.data.cl_layer_falloff);
	density = mix(density * d_s, density, config.data.cl_layer_falloff);
	density *= mask_and_alt_density;

	return clamp(density, 0.0, 1.0);
}

vec4 cloud_march(vec3 start, vec3 dir, float max_travel_dist, out float depth) {
	float min_step_size = config.data.cl_min_step_size * config.data.cl_global_scale;
	float deband = config.data.cl_deband;

	float step_size = min_step_size;
	float travel_dist = step_size;

	float density;
	float scatter_lumin;
	vec3 pos = start;
	vec3 l_pos;
	vec3 l_dir;
	vec4 color_sample;
	vec4 color = vec4(0.0);

	vec3 color_low = vec3(0.0);
	vec3 color_ambient = vec3(0.005);
	vec4 color_atmo = vec4(0.0);
	vec3 color_atmo_applied;

	vec3 up = vec3(0.0, 1.0, 0.0);  // Used for flat_world
	vec3 base = vec3(0.0, config.data.radius, 0.0);  // Used for flat_world
	float effective_radius = config.data.radius;
	float planet_occlusion_atten = 0.05 * config.data.radius;
	if (config.data.flat_world) {
		effective_radius = 50.0 * config.data.cl_global_scale;
		planet_occlusion_atten = 0.05;
	}

	float filter_threshold = 0.0005;
	float light_pen = config.data.cl_light_pen * config.data.cl_global_scale;
	for (int i = 0; i < config.data.cl_steps; i++) {
		if (travel_dist > max_travel_dist) break;
		if (color.a > 0.5) depth = min(depth, travel_dist);
		if (color.a >= 1.0) {
			// depth = travel_dist;
			break;
		}

		pos = start + dir * travel_dist;
		density = clamp(cloud_density_at_pos(pos) * config.data.cl_density_scalar, 0.0, 1.0);
		if (config.data.cloud_atmo_light_enable) {
			color_atmo = color_through_atmo(start, dir, travel_dist, 5, true);
		}

		if (density > filter_threshold) {
			vec3 up_normal = normalize(pos - config.data.pos);

			color_sample.a = clamp(density, 0.0, 1.0);

			scatter_lumin = 0.0;
			l_dir = normalize(config.data.light_pos - pos);
			vec2 hit;
			vec2 planet_hit;
			if (config.data.flat_world) {
				hit = vbox_intersect(pos, l_dir, base, config.data.atmo_alt);
				planet_hit = vec2(0.0);
				planet_hit.y = plane_intersect(pos, l_dir, up * config.data.radius, up);
			} else {
				hit = sphere_intersect(pos, l_dir, config.data.pos, config.data.radius + config.data.atmo_alt);
				planet_hit = sphere_intersect(pos, l_dir, config.data.pos, config.data.radius);
			}
			float dist_atmo = hit.y;
			if (planet_hit.y < planet_occlusion_atten) {
				for (int j = 1; j <= 5; j++) {
					l_pos = pos + l_dir * light_pen * float(j);
					scatter_lumin += cloud_density_at_pos(l_pos) * config.data.cl_density_scalar;
				}
				scatter_lumin = 1.0 - clamp(scatter_lumin / config.data.cl_light_scatter, 0.0, 1.0);
				// Normalize flight distance by quarter of total atmo radius
				float flight_through_atmo = clamp(dist_atmo * 5.0 / (effective_radius + config.data.atmo_alt), 0.0, 1.0);
				scatter_lumin *= 1.0 - flight_through_atmo;
			} else {
				dist_atmo = planet_hit.x;
				scatter_lumin = 0.0;
			}
			if (config.data.cloud_atmo_light_enable) {
				// Get color from star in sky, sky towards star (sans star), and overhead sky
				// Should add up to 1.0 when combined (so these are percents from each);
				color_atmo_applied = color_through_atmo(pos, l_dir, dist_atmo, 4, true).rgb * 0.99;
				color_atmo_applied += color_through_atmo(pos, l_dir, dist_atmo, 1, false).rgb * 0.002;
				color_atmo_applied *= 0.5;
			} else {
				color_atmo_applied = color_ambient;
			}

			color_sample.rgb = mix(color_atmo_applied * 0.2, color_atmo_applied,
				powder_beers_lumin(density, config.data.cl_beers, config.data.cl_powder));
			vec3 scatter_color = mix(color_atmo_applied, config.data.cl_color, scatter_lumin * 1.0);
			color_sample.rgb = mix(color_sample.rgb, scatter_color, scatter_lumin);
			color_sample.rgb = clamp(color_sample.rgb, color_low, config.data.cl_color);

			color_sample.rgb = mix(color_sample.rgb, (color_sample.rgb + color_atmo.rgb * 3.0) * 0.5, color_atmo.a);

			color.rgb = mix(color.rgb, color_sample.rgb, (1.0 - color.a) * color_sample.a);
			color.a = mix(color.a, 1.0, color_sample.a);
		}
		
		step_size *= config.data.cl_step_scalar * rand_near_one(deband);
		deband = clamp(deband * config.data.cl_deband_scalar, 0.0, 1.0);
		travel_dist += step_size;
	}

	//depth = min(depth, travel_dist);
	return color;
}

void main() {
	ivec2 uv = ivec2(gl_GlobalInvocationID.xy);
	if (uv.x >= params.size.x || uv.y >= params.size.y) return;
	seed = rand_seed_2d(vec2(uv));

	// highp float depth_planar = imageLoad(inout_depth, uv).r;
	float depth_planar = imageLoad(inout_depth, uv).r;
	// To get proper screen_uv it's easier to scale up and use viewport_size.
	// Since params.size is ceil-ed from (viewport_size / params.scale_down),
	// X or Y may have partial pixels (overscanned); doesn't matter for drawing,
	// but does matter for screen space sampling to get correct dir from ray_screen.
	vec2 screen_uv = get_screen_uv(uv, scene.data.viewport_size / params.scale_down);
	vec3 cam_forward = get_cam_forward(scene.data.inv_view_matrix);
	vec3 cam_pos = get_cam_world_pos(scene.data.inv_view_matrix);
	vec3 dir = ray_screen(scene.data.inv_view_matrix, scene.data.inv_projection_matrix, screen_uv);
	// highp float depth_lim = depth_planar / dot(dir, cam_forward);
	float depth_lim = depth_planar / dot(dir, cam_forward);
	vec4 color = vec4(0.0);

	bool is_valid = false;
	vec2 hit;
	vec3 start_pos = vec3(0.0);
	float atmo_travel_dist = 0.0;
	float max_travel_dist = 0.0;
	if (config.data.flat_world) {
		hit = vbox_intersect(cam_pos, dir, vec3(0.0, config.data.radius, 0.0), config.data.atmo_alt);
		if (config.data.dist_limit > 0.0 && hit.x > config.data.dist_limit) {
			hit.y = 0.0;
		}
		if (hit.y > 0.0 && hit.x <= depth_lim) {
			start_pos = cam_pos + dir * hit.x;
			max_travel_dist = min(
				min(depth_lim - hit.x, hit.y),
				100.0 * config.data.cl_global_scale + config.data.atmo_alt
			);
			is_valid = true;
		}
	} else if (sphere_in_view(cam_pos, dir, config.data.pos, config.data.radius + config.data.atmo_alt, depth_lim)) {
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

	/* DEBUG: Use ray-sphere for planet (at same size -2.0 radius of atmo) */
	// depth_lim = scene.data.z_far;
	// if (sphere_in_view(cam_pos, dir, config.data.pos, config.data.radius + config.data.atmo_alt, depth_lim)) {
	// 	vec2 hit = sphere_intersect_prechecked(cam_pos, dir, config.data.pos, config.data.radius + config.data.atmo_alt);
	// 	vec2 hit_planet = sphere_intersect_prechecked(cam_pos, dir, config.data.pos, config.data.radius);
	// 	// overwrite depth_lim with valid distance from planet when hit
	// 	if (hit_planet.y > 0.0) {
	// 		depth_lim = hit_planet.x;
	// 	}
	// 	if (hit.y > 0.0 && hit.x <= depth_lim) {
	// 		start_pos = cam_pos + dir * hit.x;
	// 		max_travel_dist = min(depth_lim - hit.x, hit.y);
	// 		is_valid = true;
	// 	}
	// }

	if (is_valid) {
		if (config.data.dist_limit > 0.0) {
			max_travel_dist = clamp(max_travel_dist, 0.0, config.data.dist_limit);
		}

		if (config.data.cloud_enable) {
			float new_depth = depth_lim;
			color = cloud_march(start_pos, dir, max_travel_dist, new_depth);
			depth_lim = new_depth;
		}

		// if (config.data.atmo_enable) {
		// 	vec4 atmo_color = color_through_atmo(start_pos, dir, max_travel_dist, 10, false);
		// 	//atmo_color *= 1.0 - 0.6 * smoothstep(0.0, 5.0, hit.x);//clamp(hit.x, 0.0, 0.5);
		// 	if (color.a < 1.0) {
		// 		color.rgb = mix(color.rgb, atmo_color.rgb, (1.0 - color.a) * atmo_color.a);
		// 		color.a = mix(color.a, 1.0, atmo_color.a);
		// 	}
		// }

		/* DEBUG: Draw hits with travel dist ratio */
		// float travel_ratio = max_travel_dist / (config.data.radius + config.data.atmo_alt);
		// color = vec4(vec3(0.0, travel_ratio, travel_ratio), 0.9);
	}

	imageStore(inout_depth, uv, vec4(depth_lim, 0.0, 0.0, 0.0));
	imageStore(out_image, uv, color);
}
