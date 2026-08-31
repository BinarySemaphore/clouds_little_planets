class_name AtmosphereProfile
extends Resource

@export_group("Planet", "planet")
@export var planet_has_atmosphere := true
@export var planet_has_clouds := true
## Planet radius.[br]
## Ignored when [member CloudsLP.flat_world] enabled.
@export var planet_radius := 50.0
@export_group("Atmosphere", "atmo")
## Max altitude from surface.
@export var atmo_height := 2.0
@export_subgroup("Physical", "atmo_p")
## Light absorption.[br]
## Measured as a percent distance of [member AtmosphereProfile.atmo_height].[br]
## Lighting further down darkens instead of brightly scatters.
@export var atmo_p_light_absorb := 0.0
## Density factor per-sample.
@export_range(0.0, 10.0) var atmo_p_density := 1.0
## Density falloff.[br]
## Larger values cause atmosphere to fade earlier.
@export var atmo_p_density_falloff := 6.0
## Multiplier for added overhead scatter near ground.[br]
## Useful to increase opacity to block out stars or objects in space.
@export var atmo_p_overhead_scatter := 1.0
@export_subgroup("Style", "atmo_s")
## Star glow size.[br]
## Dot-angle relative to view and star light.
@export var atmo_s_star_glow := 0.002
## Daylight color.
@export var atmo_s_color_direct := Color(0.0, 0.506, 0.902)
## Sunset color (partial).[br]
## Sunset color absorption multiplies this. It will darken
## (ex: yellow will be red).
@export var atmo_s_color_tangent := Color(0.98, 0.737, 0.0)
## Distance relative to [member AtmosphereProfile.atmo_height] where horizon
## haze starts.
@export_range(0.0, 10.0) var atmo_s_haze_start := 2.0
## Distance relative to [member AtmosphereProfile.atmo_height] where horizon
## haze reaches maximum.
@export_range(0.0, 10.0) var atmo_s_haze_max := 5.0
## Dot-angle relative to planet normal and star light where sunset starts.[br]
## [code]1.0[/code] is light overhead.[br]
## [code]0.0[/code] is perpendicular (light half set on horizon).[br]
## [code]-1.0[/code] is furthest from light (midnight).
@export_range(-1.0, 1.0) var atmo_s_sunset_start := 0.5
## Dot-angle relative to planet normal and star light where sunset reaches
## maximum.[br]
## [code]1.0[/code] is light overhead.[br]
## [code]0.0[/code] is perpendicular (light half set on horizon).[br]
## [code]-1.0[/code] is furthest from light (midnight).
@export_range(-1.0, 1.0) var atmo_s_sunset_max := 0.0
@export_group("Clouds")
@export_subgroup("Style", "cld_s")
## Cloud base color (when fully illuminated).
@export var cld_s_color := Color.WHITE
## Cloud light penetration.[br]
## Distance per light sampling.
@export var cld_s_light_pen := 0.05
## Cloud light passthrough.[br]
## Lower values allow more light through denser clouds.
@export var cld_s_light_scatter := 5.0
## Cloud interior lighting.
@export var cld_s_beers_factor := 6.0
## Cloud silver-lining lighting.
@export var cld_s_powder_factor := 6.5
## Cloud density multiplier.
@export var cld_s_density_factor := 1.0
@export_subgroup("Animation", "cld_a")
@export var cld_a_enabled := true
## Animation pausable in game for [member SceneTree.paused].
@export var cld_a_pausable := true
## Reverse animation.
@export var cld_a_reverse := false
## Noise progression for details (noise medium, small, and wisp).
@export var cld_a_detail_rate := 0.5
## Noise progression for position (noise large).
@export var cld_a_position_rate := Vector3.ONE
## Mask progression.
@export var cld_a_mask_rate := Vector2(1.0, 0.0)
@export_subgroup("Noise Adjust", "cld_nsa")
## Density from noise multiplication falloff.[br]
## [code]0.0[/code] is maximum influence from medium and small.[br]
## [code]1.0[/code] is zero influence from medium and small, large noise only.
@export_range(0.0, 1.0) var cld_nsa_layer_falloff := 0.25
## Density from noise threshold range min to max.[br]
## Equivalent to density = [code]smoothstep[/code](x, y, noise);[br]
## Applies only to cloud density from noises large, medium, and small;
## does not impact height, mask, and wisp.
@export var cld_nsa_threshold := Vector2(0.5, 0.8)
## Wisp noise prominence.
@export var cld_nsa_wisp_factor := 0.2
## Total rescaling to match scene.[br]
## [code]1.0[/code] matches well with 100m diameter planets.
@export var cld_nsa_global_scale := 1.0
## Noise (large, medium, small, wisp) individual scaling.
@export var cld_nsa_scale := Vector4(10.0, 2.0, 2.0, 1.0)
## Mask Latitude and Longitude offset.
@export var cld_nsa_mask_offset := Vector2.ZERO
## Noise 3D offset.
@export var cld_nsa_offset := Vector3.ZERO
@export_subgroup("Noise", "cld_ns")
## Height / Altitude mask (exponential).[br]
## Channels:[br]
## - Red: Cloud density[br]
## - Green: Exponential additional scaling[br]
## - Blue: Mask Lat / Long additional offset
@export var cld_ns_height: GradientTexture1D
## Cloud Lat / Long mask.
@export var cld_ns_mask: Texture2D
## Individual cloud large noise.
@export var cld_ns_large: Texture3D
## Individual cloud medium noise.
@export var cld_ns_medium: Texture3D
## Individual cloud small noise.
@export var cld_ns_small: Texture3D
## Individual wisp noise.[br]
## Wisps apply at height and mask edges.
@export var cld_ns_wisp: Texture3D
