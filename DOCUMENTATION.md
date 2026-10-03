# HyperDuper Vanilla — Architecture & Technical Documentation

> **HyperDuper Vanilla** is an experimental, performance-tuned community fork of [**Super Duper Vanilla**](https://github.com/Eldeston/Super-Duper-Vanilla) (by [@Eldeston](https://github.com/Eldeston) / FlameRender Studios).
> 
> **Disclaimer & Maintenance Notice**: This project is provided strictly on an **"AS IS"** basis without guarantees or warranties of any kind. Maintenance may not be active or may be sporadic. Developers are warmly invited to fork, experiment, and adapt this code.
> 
> **AI Vibecoding Disclosure**: This fork is developed with extensive use of AI pair-programming and vibecoding for rapid iteration, shader mathematics experimentation, and UI/UX design. All shader code is verified via our automated Quality Gate pipeline.

---

# Coding Standards & Guidelines

* **Performance First**: Minimizing resource utilization, avoiding redundant buffer reads, and maximizing framerate is top priority.
* **Readable Code**: Maintain descriptive uniform and variable names, document mathematical derivations, and format code cleanly.
* **Continuous Validation**: All changes must pass `python3 scripts/quality_gate.py` (GLSL compilation, i18n consistency, cyclomatic complexity, and include resolution).

---

# GLSL Dialect & Specifications

The pipeline targets **GLSL 3.3 compatibility** across the main stages, with the exception of `gbuffers_line` which operates on **GLSL 3.3 core**.

For specifications, refer to the [Khronos GLSL 3.30 Specification](https://registry.khronos.org/OpenGL/specs/gl/GLSLangSpec.3.30.pdf).

---

# Framebuffer Architecture

The pipeline utilizes 6 shared framebuffers to minimize VRAM bandwidth and maximize throughput:

| Buffer    | Format         | Channel Usage / Multiplexing                                                              |
| --------- | -------------- | ----------------------------------------------------------------------------------------- |
| `colortex0` | R11F_G11F_B10F | Clouds (RG) / Bloom Downsample & Upsample Pyramid (RGB)                                   |
| `colortex1` | RGB16_SNORM    | Packed Surface Normals (RGB)                                                              |
| `colortex2` | RGBA8          | Albedo (RGB), Screen Space Ambient Occlusion [SSAO] (A)                                    |
| `colortex3` | RGB8           | Metallic (R), Smoothness (G), Emissive / Translucent Mask (B) / Main LDR (RGB) / FXAA (RGB) |
| `colortex4` | R11F_G11F_B10F | Main HDR Color (RGB) / Vanilla Skybox (RGB)                                               |
| `colortex5` | RGBA16F        | TAA History (RGB) / Previous Frame Buffer (RGB), Auto Exposure Log-Luminance (A)          |

---

# Multi-Dimension Architecture

HyperDuper Vanilla features a modular, multi-dimension pipeline that allows individual worlds to define distinct lighting, atmospheres, and celestial behaviors while sharing core rendering libraries.

### Dimension Routing (`shaders/dimension.properties`)
Dimensions are mapped to shader world configurations:
```properties
# Overworld (fallback for all standard dimensions)
dimension.world0 = *

# The Nether (devoid of direct sunlight; fog-dominated)
dimension.world-1 = minecraft:the_nether minecraft:nether undergarden:undergarden

# The End (cosmic void with central black hole)
dimension.world1 = minecraft:the_end minecraft:end
```

### Dimensions Menu Hierarchy (`shaders/shaders.properties`)
The GUI hierarchy provides clean separation and easy expansion:
```properties
screen.DIMENSIONS = \
    [BLOCK_LIGHT_COLOR] <empty> \
    <empty> <empty> \
    [OVERWORLD_SETTINGS] [NETHER_SETTINGS] \
    [END_SETTINGS] <empty>
```
* **Top Row**: Global options common to all dimensions (e.g. `[BLOCK_LIGHT_COLOR]`, configuring warm torchlight and lantern light across all worlds).
* **Divider**: Clean visual separation.
* **Dimension List**: Individual dimension subscreens. To add a new dimension (e.g. Aether), add `[AETHER_SETTINGS]` next to `[END_SETTINGS]` and route it in `dimension.properties`.

---

# New Features & Atmospheric Subsystems

### 1. Atmospheric Godrays (`shaders/lib/atmospherics/godrays.glsl`)
* **Raymarched Crepuscular Rays**: Calculates light shafts streaming from the sun and moon through clouds, foliage, water, and terrain.
* **Adaptive Step Optimization (`GODRAYS_ADAPTIVE_STEPS`)**: Dynamically concentrates sample steps when the player looks toward the sun, **doubling FPS when facing the celestial body** with zero visual loss.
* **Water Transmission (`GODRAYS_WATER_TRANSMISSION`)**: Allows sunbeams to stream into water bodies and through stained glass by sampling translucent depth buffers.

### 2. Procedural Meteor Showers (`shaders/lib/atmospherics/meteorShowers.glsl`)
* **Nighttime Shooting Stars**: Procedural dynamic meteors featuring glowing leading pixel heads, ionization tails, and exponential trail fades.
* **Customization**:
  * **Rarity Scheduling**: Every night, periodic (2-3, 4-5, 7-8, 12-15 nights), or lunar cycle (New Moon).
  * **6 Color Palettes**: Electric Blue, Cosmic Violet, Emerald Green, Amber Gold, Diamond White, and Prismatic (per-meteor randomized colors).
  * **Activity Modes**: Constant stream vs dynamic waxing/waning shower waves.
  * **Sky Distribution**: Panoramic full sky, directional stream, or radiant-focused.

### 3. Procedural Milky Way & Stars (`shaders/lib/atmospherics/milkyWay.glsl`)
* **Stylized Galactic Band**: Procedural cosmic ribbon with thousands of twinkling square stars and nebula dust across the clear night sky.
* **Star Rotation Styles (`STAR_ROTATION`)**: Aligned square grid stars or organic random star rotation angles.

### 4. Volumetric Auroras (`shaders/lib/atmospherics/aurora.glsl`)
* **Northern Lights**: Multi-tiered volumetric curtains flowing from pink tops to emerald centers and electric blue bottoms in cold, snowy, and icy biomes.

### 5. Double Rainbows (`shaders/lib/atmospherics/rainbow.glsl`)
* **Analytical Optics**: Renders primary and secondary rainbow arches opposite the sun or moon during rainfall with partial sunlight.
* Follows `SUN_MOON_ROUNDNESS` geometry (circular rainbow or square rainsquare).

### 6. Dynamic Weather & Humidity Fog (`shaders/shaders.properties`)
* **Dynamic Weather Cycle**: Multi-day procedural weather clock generating gradual overcast transitions.
* **Dynamic Biome Fog**: Couples weather moisture with biome humidity: swamps, rivers, and jungles develop thick morning mist, while arid biomes stay clear.
* **Pale Garden Fog**: Light-gray atmospheric gloom for the Pale Garden biome.

### 7. The End Dimension Lighting (`shaders/world1/world.glsl`)
* **Black Hole Directional Light (`END_BH_LIGHT`)**: Faint permanent directional light cast from the cosmic black hole accretion disk.
* **Ender Dragon Boss Fog (`END_BOSS_FOG`)**: Cinematic purple atmospheric fog during the dragon encounter.

### 8. Voxy LOD Integration (`shaders/main/modded/voxy.glsl`, `shaders/voxy.json`)
* Full pipeline support for Voxy distant Level-of-Detail terrain across all dimensions with PBR material lookups, custom UBO layout, and horizon fog integration.

---

# Program Pipeline & Pass Classification

### G-Buffer Passes
| Program               | Blend Mode  | Shading Complexity | Description / Role                                        |
| --------------------- | ----------- | ------------------ | --------------------------------------------------------- |
| `gbuffers_terrain`    | Solid       | Complex (PBR)      | Solid world blocks, terrain displacement, animated waving |
| `gbuffers_water`      | Translucent | Complex (PBR)      | Water surface, wave normals, absorption, foam             |
| `gbuffers_entities`   | Translucent | Complex (PBR)      | Living entities, mobs, players, armor, item frames        |
| `gbuffers_block`      | Translucent | Complex (PBR)      | Translucent blocks, stained glass, ice, portals           |
| `gbuffers_clouds`     | Translucent | Simple             | Cloud layer rendering                                     |
| `gbuffers_weather`    | Translucent | Simple             | Animated rain and snow precipitation                      |
| `gbuffers_skytextured`| Solid       | Simple             | Celestial textures (sun, moon, End sky backdrop)          |

### Deferred Passes
| Program               | Description / Role                                                                        |
| --------------------- | ----------------------------------------------------------------------------------------- |
| `deferred`            | Screen Space Ambient Occlusion (SSAO) pass (disabled via shaders.properties if SSAO off)  |
| `deferred1`           | Atmospheric lighting, sky rendering, direct sunlight/moonlight, and shadow mapping       |

### Composite Passes
| Program               | Description / Role                                                                        |
| --------------------- | ----------------------------------------------------------------------------------------- |
| `composite`           | Volumetric clouds, volumetric haze, godrays, and underwater caustics                      |
| `composite_translucent`| Translucent composite blending and reflections                                           |
| `composite1_taa`      | Temporal Anti-Aliasing (TAA) history accumulation                                         |
| `composite2_motionblur`| Velocity-based motion blur (disabled via shaders.properties if motion blur off)            |
| `composite3_dof`      | Depth of Field bokeh blur (disabled via shaders.properties if DOF off)                    |
| `composite4_bloom_pass1`| Bloom downsampling and bright-pass extraction (disabled if bloom off)                    |
| `composite5_bloom_pass2`| Bloom upsampling and blur accumulation (disabled if bloom off)                            |
| `composite6_tonemap`  | Color grading, contrast, saturation, exposure, and tonemapping rolloff                    |
| `final`               | FXAA post-processing, block outlines, retro filter, and final output display             |

---

# Quality Gate & Testing Tools

The repository contains automated tools to maintain code quality, ensure valid compilation, and benchmark performance:

### Continuous Quality Gate (`python3 scripts/quality_gate.py`)
Executes a 4-stage validation pipeline:
1. **GLSL Compilation**: Validates all 240+ shader variants against OpenGL/Iris specifications using `glslangValidator`.
2. **i18n Translation Consistency**: Validates `en_US.lang` against `shaders.properties`, checking coverage, duplicate keys, and syntax.
3. **File Length & Complexity**: Enforces Single Responsibility and KISS guidelines (file lengths and McCabe cyclomatic complexity).
4. **Include Integrity**: Ensures every `#include` directive resolves to an existing file.

### Static Performance Profiler (`python3 scripts/profile_shaders.py`)
* Analyzes all shader passes across Overworld, Nether, and End dimensions.
* Quantifies texture fetch counts, distinct sampler usage, transcendental math operations (`pow`, `exp`, `sin`, `cos`, `atan`), loop iterations, and branching.
* Calculates a weighted **GPU Cost Index** to identify optimization bottlenecks.
* Supports regression benchmarking: `python3 scripts/profile_shaders.py --compare baseline.json current.json`.

### In-Game Runtime Profiling
* **Live Reload**: Press **`R`** in-game to recompile and hot-reload shaders instantly without restarting Minecraft.
* **Spark Profiler**: Run `/sparkc profiler start` and `/sparkc profiler stop` to generate CPU/GPU render thread call trees.
* **RenderDoc / Nsight**: Launch with `task run:renderdoc` or `task run:nsight` for draw-call and hardware counter inspection.