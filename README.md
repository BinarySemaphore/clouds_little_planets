# Clouds for Little Planets (v1.0)
Godot 4.6 Cloud and Atmospheric compositor for little planets and flat worlds

* [Features](#features)
  * [Screenshots](#screenshots)
* [Known Issues](#known-issues)
* [Install](#install)
  * [Godot AssetLib](#godot-assetlib)
  * [Direct (from GitHub)](#direct-from-github)
* [Guide](#guide)
  * [Video Guide](#video-guide)
  * [Getting Started](#getting-started)
    * [Setup](#setup)
    * [Configuring](#configuring)
  * [Creating and Saving Profiles](#creating-and-saving-profiles)
  * [Script Integration](#script-integration)
  * [Custom Modification](#custom-modification)
    * [Shaders](#shaders)
* [Performance](#performance)
   * [Bench_01](#bench_01)
   * [Bench_02](#bench_02)
* [Testing](#testing)
  * [Example Project](#example-project)
* [Thirdparty](#thirdparty)
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

### Screenshots
| <img src="github/screenshots/20260724_180734.png"> | <img src="github/screenshots/20260724_180925.png"> | <img src="github/screenshots/20260724_180901.png"> |
| --- | --- | --- |
| <img src="github/screenshots/20260724_180749.png"> | <img src="github/screenshots/20260724_180806.png"> | <img src="github/screenshots/20260724_180953.png"> |
| <img src="github/screenshots/20260804_203810.png"> | <img src="github/screenshots/20260804_205150.png"> | |

## Known Issues
- Embedded objects (like buildings in clouds):
  - Edges are down scaled
  - Cloud banding in some situations (near walls for dense clouds)
- Untested: Complex foreground transparency
- Untested: MSAA

## Install
### Godot AssetLib
_Release Pending..._
### Direct (from GitHub)
1) Go to [Releases](https://github.com/BinarySemaphore/clouds_little_planets/releases)
1) Download the latest `clouds_lp.zip` file
1) In Godot, ensure your project has `addons` folder
1) Click on `AssetLib` at the top
1) Find `Import...` on the top right of `AssetLib` window
1) Select the downloaded `clouds_lp.zip` file and click `Open`
1) In the "__Configure Asset Before Installing__" window, click `Change Install Folder`
1) Select `addons` folder and click `Select This Folder`
1) Click `Install`
1) From the menu-bar click `Project` > `Project Settings`
1) Select `Plugins` tab in the "Project Settings" window
1) Enable "__CloudsLP__"

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

## Performance
Frame times are measured using Godot's visual profiler for this specific compositor effect only.
### Bench_01:
- __Scene__: Earth - avg cloud coverage 2 layers
- __OS__: Linux
- __Hardware__: Nvidia GeForce RTX 2060 Max-Q (messured clock at 1.6 GHz)
- __VRAM (includes planet textures)__:
  - __Textures__: 209.6 MB
  - __Buffers__: 20.94 MB
- __Frame Times (avg)__:
  - __Settings (S1)__: 1920x1080 | Scale Down "Quarter" | Quality "High"
  - __Settings (S2)__: 1920x1080 | Scale Down "Eighth" | Quality "Medium"
    | Scenario | Times (S1) | Times (S2) |
    | --- | --- | --- |
    | Ground-to-Sky | 2.78 ms | 1.67 ms |
    | Flight | 5.18 ms | 2.19 ms |
    | Space-to-Planet | 11.96 ms | 3.18 ms |
### Bench_02:
- __Scene__: Earth - avg cloud coverage 2 layers
- __OS__: Linux
- __Hardware__: AMD Ryzen 9 4900HS with Radeon Graphics (messured clock at 1.8 GHz)
- __VRAM (includes planet textures)__:
  - __Textures__: 219.1 MB
  - __Buffers__: 20.94 MB
- __Frame Times (avg)__:
  - __Settings (S1)__: 1920x1080 | Scale Down "Quarter" | Quality "High"
  - __Settings (S2)__: 1920x1080 | Scale Down "Eighth" | Quality "Medium"
    | Scenario | Times (S1) | Times (S2) |
    | --- | --- | --- |
    | Ground-to-Sky | 12.06 ms | 6.97 ms |
    | Flight | 20.38 ms | 9.18 ms |
    | Space-to-Planet | 36.74 ms | 11.44 ms |

## Testing
This addon repository is its own testable Godot project (Godot 4.6 | Forward+ rendering).

### Example Project
1) Download this repository
   1) Find and select `Code` at the top of GitHub
   1) Click `Download ZIP`
1) Extract project to an appropriate directory
1) Open Godot Project Manager
1) Click `Scan` or `Import` (depends on where you put the project)
1) Open the project
1) Open `test.tscn` scene
   - You should see Earth with an atmosphere and low-res clouds
   - In `WorldEnvironment` > `Compositor` > `Compositor Effects` > `0` will be __CloudsLP__
   - __CloudsLP__ has all the possible configurations for both atmosphere and cloud generation
   - Any `Profile` should expand for specific configuration
1) Running the scene will use higher-res clouds and provides a controllable camera
   - Camera Controls:
     - `W A S D`: Move Forward, Left, Back, Right
     - `Q Z`: Move Up and Down
     - `Shift (hold)`: Increase movement speed
     - `Ctrl (hold)`: Decrease movement speed
     - `Arrows`: Rotate
   - Default speeds can be adjusted from the edtior prior to launching (_Move Speed_ and _Turn Speed_)

## Thirdparty
### Earth Textures:
In Test/Example project (not part of the addon)
- Source: https://www.solarsystemscope.com/textures/
- License: [Creative Commons License 4.0](https://creativecommons.org/licenses/by/4.0/)
- Files
  - `8k_earth_daymap.jpg`
  - `8k_earth_specular_map.png`
  - `8k_earth_normal_map.png`

## Notable Mentions:
- [Sunshine Clouds 2](https://github.com/Bonkahe/SunshineClouds2): Helping me learn about Godot compositors and cloud marching
