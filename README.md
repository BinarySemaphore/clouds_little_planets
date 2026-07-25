# Clouds for Little Planets (Early Release)
Godot 4.6 Cloud and Atmospheric compositor for little planets (optional flat world WIP)

* [Features](#features)
  * [Screenshots](#screenshots)
* [Install](#install)
  * [Godot AssetLib](#godot-assetlib)
  * [Direct (from GitHub)](#direct-from-github)
* [Guide](#guide)
  * [Video Guide](#video-guide)
* [Test](#test)
  * [Example Project](#example-project)
* [Thirdparty](#thirdparty)
* [Notable Mentions](#notable-mentions)

## Features
- Inside and out (from space) atmospheric and cloud rendering
- Volumetric cloud generation
- Profiles (for quick swapping in editor or during runtime)
  - Planet and Quality profile resources
- Time progression (WIP)
- Wind (WIP)

### Screenshots
| <img src="github/screenshots/20260724_180734.png"> | <img src="github/screenshots/20260724_180925.png"> | <img src="github/screenshots/20260724_180901.png"> |
| --- | --- | --- |
| <img src="github/screenshots/20260724_180749.png"> | <img src="github/screenshots/20260724_180806.png"> | <img src="github/screenshots/20260724_180819.png"> |
| <img src="github/screenshots/20260724_180953.png"> | <img src="github/screenshots/20260724_181045.png"> | |

## Install
### Godot AssetLib
_Release Pending..._
### Direct (from GitHub)
1) Go to [Releases](https://github.com/BinarySemaphore/clouds_little_planets/releases)
1) Download the latest `*.zip`
1) In Godot, ensure your project has `addons` folder
1) click on `AssetLib` at the top
1) Find `Import...` on the top right of `AssetLib` window
1) Select the downloaded ZIP file and click `Open`
1) In the "Configure Asset Before Installing" window, click `Change Install Folder`
1) Select `addons` folder and click `Select This Folder`
1) Click `Install`
1) From the menu-bar click `Project` > `Project Settings`
1) Select `Plugins` tab in the "Project Settings" window
1) Enable `CloudsLP`

## Guide
_In Progress..._
### Video Guide
_In Progress..._

## Test
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
   - In `WorldEnvironment` > `Compositor` > `Compositor Effects` > `0` will be `CloudsLP`
   - `CloudsLP` has all the possible configurations for both atmosphere and cloud generation
   - Any `Profile` should expand for specific configuration
1) Running the scene will use higher-res clouds and a controllable camera is provided

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
