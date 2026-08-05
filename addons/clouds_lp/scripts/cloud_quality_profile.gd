class_name CloudQualityProfile
extends Resource

## Number of sampling steps.[br]
## More steps looks better, but at the cost of performance.
@export var steps := 100
### Maximum distance per sampling step.[br]
### Smaller looks better, but limits rendering distance.[br]
### Distance can be extended using [member CloudQualityProfile.step_scalar].[br]
### [br][color=white]Note:[/color] step size is automatically set by scene depth
### over [member CloudQualityProfile.steps], this is the limiting/maximum step
### size to handled large distances.
#@export_range(0.00001, 10.0, 0.0001) var max_step_size := 0.02
## Distance per sampling step.[br]
## Smaller looks better, but limits rendering distance.[br]
## Distance can be extended using [member CloudQualityProfile.step_scalar].[br]
## [br][color=white]Note:[/color] Auto scales with
## [member CloudsLP.profile] > [code]Clouds > Noise Adjust > Global Scale[/code]
## ([member AtmosphereProfile.cld_nsa_global_scale]).
@export_range(0.00001, 10.0, 0.0001) var step_size := 0.02
## Increases step size after each sample step.[br]
## Similar to LOD: reduces cloud visual fidelity by distance.[br]
## Extends rendering distance, but introduces artifacts.[br]
## [br][color=white]Note:[/color] See [member CloudQualityProfile.debanding_noise].
@export_range(1.0, 2.0) var step_scalar := 1.04
## Add random-noise when sampling to reduce banding and flickering.
@export_range(0.0, 1.0) var deband_noise := 0.1
## [member CloudQualityProfile.deband_noise] scaling each step
## (Noise reduction by distance).
@export_range(0.0, 1.0) var deband_noise_scalar := 0.1
