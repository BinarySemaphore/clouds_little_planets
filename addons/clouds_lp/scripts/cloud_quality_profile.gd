class_name CloudQualityProfile
extends Resource

## Number of sampling steps.[br]
## More steps looks better, but at the cost of performance.
@export var steps := 100
## Minimum distance per sampling step.[br]
## Smaller looks better, but limits rendering distance.[br]
## Can be extended using [code]step_scalar[/code].
@export_range(0.00001, 10.0, 0.0001) var min_step_size := 0.02
## Increases [code]min_step_size[/code] each step.[br]
## Like LOD, reduces cloud visual fidelity by distance.[br]
## Extends rendering distance, but introduces artifacts
## (see [code]debanding_noise[/code]).
@export_range(1.0, 2.0) var step_scalar := 1.04
## Add spacial-noise when sampling to reduce banding and flickering.
@export_range(0.0, 1.0) var deband_noise := 0.1
## Deband Noise scaling each step (Noise reduction by distance).
@export_range(0.0, 1.0) var deband_noise_scalar := 0.1
