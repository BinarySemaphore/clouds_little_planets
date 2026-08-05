# Clouds for Little Planets (v1.0 - Addon)
Cloud and Atmospheric compositor for little/big planets and flat worlds for Godot 4.6

* [Features](#features)
* [Known Issues](#known-issues)
* [Guide](#guide)
  * [Video Guide](#video-guide)
  * [Getting Started](#getting-started)
    * [Setup](#setup)
    * [Configuring](#configuring)
  * [Creating and Saving Profiles](#creating-and-saving-profiles)
  * [Script Integration](#script-integration)
  * [Custom Modification](#custom-modification)
    * [Shaders](#shaders)
* [Notable Mentions](#notable-mentions)

## Features
- Inside and out (from space) atmospheric and cloud rendering
- Art driven atmospherics
  - Physics inspired, but art simplified (adjust haze and sunsets based on distance and vector-angles)
- Volumetric cloud generation
  - Cloud atmosphere relighting
- Profiles (for quick swapping in editor or during runtime)
  - Planet and Quality profile resources
- Radial (large scale / toy planet) or Flat world rendering
- Multiple cloud adjustable layers
- Rescaling
- Time progression (animation)
- Wind (WIP)

## Known Issues
- Embedded objects (like buildings in clouds):
  - Edges are down scaled
  - Cloud banding in some situations (near walls for dense clouds)
- Untested: Complex foreground transparency
- Untested: MSAA

## Guide
Clouds for Little Planets (__CloudsLP__) is a compositor.
Compositors can be applied as effects onto any `WorldEnvironement` or `Camera3D` node.

### Video Guide
_In Progress..._

### Getting Started
#### Setup
1) Open or Create a 3D Scene
1) Add a `WorldEnvironment` to the node tree if one is not currently in the scene
   - Optional: configure the `Environment` > `Background` with mode _Custom Color_ and set to black for space look
1) For `WorldEnvironment` > `Compositor`, click on the `<empty>` indicator
1) Select `Compositor` to create a compositor
   - Learn more about compositors at the official Godot docs [here (4.6)](https://docs.godotengine.org/en/4.6/tutorials/rendering/compositor.html#the-compositor)
1) Click the new compositor to see `Compositor Effects`
1) Click the _Array_ to expand the effects list
1) Click `Add Element`
1) Click the _Folder-with-Plus_ icon next to `<empty>` in the effects list
1) Select `CloudsLPTemplate.tres`
   - Make sure "_Addons_" is toggled on in the selector window if you don't see anything
1) Check it's working
   - Center your viewer and zoom out to __85__ or more
   - There should be a hollow sphere with colors and cloud-like blobs
1) Right Click on the `CloudsLPTemplate.tres` and "_Make Unique_" or "_Save As_"
   - This copies the template and allows you to configure the compositor settings
   - "_Make Unique_" is like "_Save As_" but embeds it with the scene
1) Click on the effect in the effects list
   - This expands to show all configurations (where everything lives)
#### Configuring
Configuration is done in the compositor, ensure the __CloudsLP__ instance is expanded (See [Setup](#setup) for details).
- Note:
  > For any profiles and other pre-loaded resources (like gradients and noise), just like with `CloudsLPTemplate.tres`, it's recommended to save or make unique prior to making any changes. You can always create new profiles or resources at anytime as well. Nearly all parameters have hover-over hints explaining their function.

- `Flat World`: Force flat world (Y axis is altitude). `Profile.Planet.Radius` will be used as sea-level.
- `Light Source`: _NodePath_ a driving `Light3D` for color and positioning.
  - Warning:
     > Godot's `CompositorEffect` is not attached to the scene tree and cannot directly resolve a relative _NodePath_. __CloudsLP__ reconstructs the lookup during initialization by locating the first named ancestor in the active scene, then resolves with the remainder of the path. The resulting `Light3D` is cached for runtime use. Restrictions from this limitation are documented directly in the parameter. Warnings and errors are given to help resolve any problems.

_In Progress..._

### Creating and Saving Profiles
_In Progress..._

### Script Integration
_In Progress..._

### Custom Modification
#### Shaders
Shaders are organized into shared `*.glslinc` include files to reduce code duplication.
Most of the actual code exists in `atmo.glslinc`, `atmo_main.glslinc`, and `cloud.glslinc`.
- __Warning__:
   >Godot treats `*.glslinc` files as text substitutions. Changes to an include file do **not** automatically trigger reimport of the `*.glsl` shaders that include it. After modifying an include, manually reimport all affected `*.glsl` shaders before reloading or running the project, or the changes will not take effect.

## Notable Mentions:
- [Sunshine Clouds 2](https://github.com/Bonkahe/SunshineClouds2): Helping me learn about Godot compositors and cloud marching
