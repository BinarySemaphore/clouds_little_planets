class_name AtmosphereProfile
extends Resource

@export_group("Planet", "planet")
@export var planet_radius := 50.0
@export var planet_has_atmosphere := true
@export var planet_has_clouds := true
@export_group("Atmosphere", "atmo")
## Max altitude from surface.
@export var atmo_height := 2.0
## Light penetration.[br]
## Measured in distance from [code]atmo_height[/code].[br]
## Lighting further down darkens instead of intensly scatters.
@export var atmo_light_pen := 2.0
## Density falloff.[br]
## Larger values cause atmosphere to fade earlier.
@export var atmo_density_falloff := 6.0
## Refractive bending.
@export var atmo_refract_bend := 0.0
## Star glow size.
@export var atmo_star_glow := 0.002
## Colors absorbed or unscattered during Rayleigh scattering.[br]
## Daylight colors subtracted.
@export var atmo_color_direct := Color(0.467, 0.675, 1.0)
## Colors absorbed or unscattered during Mie scattering.[br]
## Sunset colors subtracted.
@export var atmo_color_tangent := Color(1.0, 0.776, 0.212)
@export_group("Clouds", "cld")
## Cloud base color (when fully illuminated).
@export var cld_color := Color.WHITE
## Cloud light penetration.[br]
## Distance per light sampling.
@export var cld_light_pen := 0.05
## Cloud light passthrough.[br]
## Lower values allow more light through denser clouds.
@export var cld_light_scatter := 5.0
## Cloud interior lighting.
@export var cld_beers_factor := 6.0
## Cloud silverlining lighting.
@export var cld_powder_factor := 6.5
## Cloud desnity multiplier.
@export var cld_density_factor := 1.0
@export_subgroup("Noise Adjust", "ns_adj")
## Density from noise multiplication falloff.[br]
## [code]0.0[/code] is maximum influence from medium and small.[br]
## [code]1.0[/code] is zero influence from mdeium and small, large noise only.
@export_range(0.0, 1.0) var ns_adj_layer_falloff := 0.25
## Density from noise threshold range min to max.[br]
## Equivalent to density = [code]smoothstep[/code](x, y, noise);[br]
## Applies only to cloud density from noises large, medium, and small;
## does not impact height, mask, and wisp.
@export var ns_adj_threshold := Vector2(0.5, 0.8)
## Wisp noise prominence.
@export var ns_adj_wisp_factor := 0.2
## Total rescaling to match scene.[br]
## [code]1.0[/code] matches well with 100m diameter planets.
@export var ns_adj_global_scale := 1.0
## Noise (large, medium, small, wisp) individual scaling.
@export var ns_adj_scale := Vector4(10.0, 2.0, 2.0, 1.0)
## Mask Latitude and Longitude offset.
@export var ns_adj_mask_offset := Vector2.ZERO
## Noise 3D offset.
@export var ns_adj_offset := Vector3.ZERO
@export_subgroup("Noise", "ns")
## Height / Altitude mask (exponential).[br]
## Channels:[br]
## - Red: Cloud density[br]
## - Green: Exponential additional scaling[br]
## - Blue: Mask Lat / Long additional offset
@export var ns_height: GradientTexture1D
## Cloud Lat / Long mask.
@export var ns_mask: Texture2D
## Individual cloud large noise.
@export var ns_large: Texture3D
## Individual cloud medium noise.
@export var ns_medium: Texture3D
## Individual cloud small noise.
@export var ns_small: Texture3D
## Individual wisp noise.[br]
## Wisps apply at height and mask edges.
@export var ns_wisp: Texture3D
