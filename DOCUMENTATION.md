# Super Duper Vanilla Documentation

Super Duper Vanilla (SDV) is a Minecraft shader pack for Iris. This document is the entry point: it summarizes the project's features, settings system, rendering pipeline, buffers, programs, and ID tables, and links to the detailed documents below.

> [!NOTE]
> This documentation page is created with the help of AI so you might find some babbling nonsense, read at your own risk!

| Document | Description |
|---|---|
| [ARCHITECTURE.md](.docs/ARCHITECTURE.md) | Rendering pipeline, framebuffer architecture, and stage execution |
| [PROGRAMS.md](.docs/PROGRAMS.md) | Shader program classifications, responsibilities, and execution order |
| [BUFFERS.md](.docs/BUFFERS.md) | Render targets, data flow, and buffer lifetimes |
| [FEATURES.md](.docs/FEATURES.md) | Rendering features and implementation references |
| [SETTINGS.md](.docs/SETTINGS.md) | Settings, profiles, defaults, and configuration options |
| [OPTIMIZATION.md](.docs/OPTIMIZATION.md) | Performance characteristics, profiling, and measurement guidance |
| [LEGACY.md](.docs/LEGACY.md) | Archived original documentation and project notes |

Documentation information:

- Documented version: 1.3.9 (unreleased, release candidate)
- Shader loader: Iris 1.6.10 or later, Minecraft 1.18.2 or later
- GLSL version: 3.3 Compatibility (`gbuffers_line` uses GLSL 3.3 Core)
- OptiFine maintenance: ended with SDV 1.3.7

> [!NOTE]
> The shader source is authoritative. If this documentation and the source disagree, trust the source and report the mismatch.

## Features

### Materials and Surface Detail

- **Physically Based Rendering (PBR)** with a metallic workflow and GGX-style specular shading.
- Four PBR modes: Off, Basic PBR, Integrated PBR (materials inferred from vanilla albedo), and LabPBR 1.3 (resource-pack materials). See [PBR modes](#pbr-modes).
- Normal maps, optional generated and slope normals, parallax occlusion mapping (LabPBR only), emissive materials, and subsurface scattering.
- Environment-dependent material response (rain wetness), plus stylized water, lava, and sculk materials with their own settings pages.

### Lighting

- Dynamic shadow mapping with configurable filtering, colored shadows, and optional entity and block-entity shadows.
- Screen-space ambient occlusion (SSAO), screen-space reflections (SSR), and experimental screen-space global illumination (SSGI, disabled by default).
- Directional lightmaps, ambient light control, and underwater caustics.

### Atmosphere and World Effects

- Sky, sun and moon (squircle, round, or vanilla), fog, border fog, ground fog, and volumetric lighting.
- Two cloud types: vanilla clouds and voxel (DDA-traced) clouds, with an optional second layer and weather-responsive behavior.
- Terrain, water, and weather animation with wind and current controls, timelapse mode, and optional world curvature.

### Post-Processing and Presentation

- Anti-aliasing: Off, FXAA, TAA, or Lite TAA + FXAA.
- Motion blur and depth of field.
- Bloom, lens flare, auto exposure, tone mapping, color tint, saturation and contrast, and vignette.
- Outlines (Standard or Dungeons style), optional retro filter, chromatic aberration, and optional sharpening.

### Mod and Modded-Dimension Integrations

- **Distant Horizons**: `dh_terrain`, `dh_generic`, and `dh_water` programs. Distant Horizons shadows and clouds are disabled in `shaders.properties`.
- **Voxy**: `voxy.json` plus `voxy_opaque` and `voxy_translucent` fragment programs.
- **Physics Mod**: `physics_ocean` and `physics_ocean_shadow` programs, controlled by `PHYSICS_OCEAN_SUPPORT`.
- **Dimensional Doors**: dedicated dimension slots (`world-2`, `world-3`, `world-4`) and block IDs for its fabric and portal blocks.
- Block IDs also cover some Farmer's Delight, Create, Undergarden, Twilight Forest, and Cobblemon Raid Dens blocks.

## Settings

Settings have several source layers:

| Source | Defines |
|---|---|
| [`shaders/lib/settings.glsl`](shaders/lib/settings.glsl) | Shared feature toggles, numeric defaults, and their value domains |
| [`shaders/shaders.properties`](shaders/shaders.properties) | Menu pages, profiles, sliders, program enable conditions, buffer sizes, and custom uniforms |
| [`shaders/lang/en_US.lang`](shaders/lang/en_US.lang) | Exact English menu labels, descriptions, and enum names |
| [`shaders/lib/lighting/shdSampleVar.glsl`](shaders/lib/lighting/shdSampleVar.glsl) | Shadow-map controls and internal sampling constants |
| `shaders/world-X/world.glsl` | Per-dimension world flags and lighting and fog defaults |

### Profiles

The main settings screen provides Potato, Low, Medium (Default), High, and Ultra. Each profile inherits from the previous one.

| Profile | Notable assignments |
|---|---|
| Potato | Vanilla clouds, FXAA, PBR mode 0, no shadows, SSAO, SSR, bloom, volumetrics, or sharpening |
| Low | Voxel clouds, PBR mode 1, shadows at 512, SSR and bloom on, 8 ray steps, caustics off |
| Medium (Default) | TAA, shadows at 1024, shadow color and filter, SSAO, rough reflections, previous-frame data, volumetrics, 16 ray steps, underwater caustics |
| High | Shadows at 2048, 32 ray steps, PBR mode 2 |
| Ultra | Shadows at 4096, 64 ray steps, sharpening, full caustics |

The full definitions live in `shaders/shaders.properties`; [SETTINGS.md](.docs/SETTINGS.md) lists them in detail.

### PBR modes

`PBR_MODE` accepts `0` to `3`. The English labels in `en_US.lang` are: `0` OFF, `1` Basic PBR, `2` Integrated PBR, `3` Lab PBR 1.3. Integrated material tables are compiled for modes `0` to `2`; extra rough-reflection materials for stone, soil, and similar blocks apply only in mode `2` with `ROUGH_REFLECTIONS`. LabPBR is mode `3` and requires a LabPBR 1.3 resource pack.

### Menu Navigation

The main screen lists Debug and the profile selector, then Post, Lighting, Atmospherics, World, PBR, and Configuration. Post contains Camera and Tonemap pages. Lighting contains Ray tracing. Atmospherics contains Cloud settings. PBR contains Parallax occlusion and iPBR pages (Water, Lava, and Sculk materials, plus normal generation). Configuration contains Overworld (Day, Night, Twilight, Fog), Nether, End, and Block light pages.

### Developer-Hidden World Settings

Many `world.glsl` values are intentionally not menu options: `WORLD_ID`, `WORLD_LIGHT`, `WORLD_SUN_MOON`, `WORLD_SUN_MOON_SIZE`, `FORCE_DISABLE_CLOUDS`, `FORCE_DISABLE_WEATHER`, `FORCE_DISABLE_DAY_CYCLE`, `WORLD_SKY_GROUND`, `WORLD_AETHER`, `WORLD_CUSTOM_SKYLIGHT`, `WORLD_STARS`, and `WORLD_VANILLA_FOG_COLOR`. `WORLDn1_VANILLA_FOGCOLI` appears as the Nether's Sky intensity when defined. Editing source macros requires a shader reload so programs recompile.

## Architecture

The frame follows five broad stages:

```text
+-------------------+    +---------+    +----------+    +--------------------+    +-------+
| Shadow programs   | -> | Gbuffers| -> | Deferred | -> | Composite programs | -> | Final |
+-------------------+    +---------+    +----------+    +--------------------+    +-------+
```

1. **Shadow programs** render depth (and optionally color) from the light's view.
2. **Gbuffers** render geometry. Some programs shade forward, others write material data for deferred shading.
3. **Deferred programs**: `deferred` computes SSAO into the alpha of `colortex2`; `deferred1` performs opaque complex shading, reflections, outlines, sky, and fog.
4. **Composite programs** run in order with explicit read and write dependencies.
5. **Final** applies the retro filter, chromatic aberration, and sharpening, and writes the screen image.

SDV is hybrid forward and deferred. There are fifteen composite programs, `composite` (slot 0) through `composite14`.

| Composite program | Main responsibility |
|---|---|
| `composite` (0) | Complex shading, reflections, and fog for forward-shaded geometry; voxel clouds for the whole frame |
| `composite1` | Half-resolution volumetric light ray march into `colortex0` |
| `composite2` | Volumetric temporal accumulation (history in `colortex6`) |
| `composite3` | Upsample volumetrics and add them to the HDR scene |
| `composite4` | TAA, and writes previous-frame color to `colortex5` |
| `composite5` | FXAA (modes 1 and 3) |
| `composite6` | Motion blur |
| `composite7` | Depth of field |
| `composite8` | Bloom tile downsample |
| `composite9`-`composite10` | Bloom blur (horizontal, then vertical) |
| `composite11` | Bloom upsampling and lens flare |
| `composite12` | Apply bloom to the HDR scene |
| `composite13` | Auto exposure (1x1 `colortex7`) |
| `composite14` | Exposure, tint, tonemapping, gamma, contrast, saturation, vignette, dithering |

Dimension-specific wrappers and settings live under `shaders/world-X/`. Enable conditions for each composite are in `shaders/shaders.properties`.

## Buffers

SDV uses eight color targets. `colortex0` and `colortex6` are half width and half height. Formats are declared in `shaders/main/final.glsl`.

| Target | Format | Main payload and lifetime |
|---|---|---|
| `colortex0` | `R11F_G11F_B10F` | Half-resolution volumetrics, then bloom intermediates. The cloud-map texture is also bound here for selected programs |
| `colortex1` | `RGB16_SNORM` | Surface normals |
| `colortex2` | `RGBA8` | Albedo in RGB; SSAO in alpha after `deferred` |
| `colortex3` | `RGB8` | Metallic (R), smoothness (G), and shading mask (B) for deferred shading; later reused as final display color |
| `colortex4` | `R11F_G11F_B10F` | Main HDR scene color |
| `colortex5` | `R11F_G11F_B10F` | Previous-frame color for TAA, SSR, and SSGI |
| `colortex6` | `RGB8` | Half-resolution volumetric history |
| `colortex7` | `R16F` | Auto exposure state |

`shadowcolor0` is `RGB8`. Depth and shadow attachments are `depthtex0`, `depthtex1`, `shadowtex0`, `shadowtex1` (with colored shadows), and `shadowcolor0`.

The blue channel of `colortex3` is a shading mask: `0` for geometry shaded in `deferred1`, and `0.5` for geometry that `composite` shades afterwards. Clear behavior: `colortex1` and `colortex4` clear to `(0, 0, 0, 1)`; `colortex0`, `colortex2`, `colortex5`, `colortex6`, `colortex7`, and `shadowcolor0` are not cleared.

## Programs

Classifications describe shading complexity: **Complex** (full PBR and lighting), **Basic** (reduced shading), **Simple** (lightweight), and **Disabled** (`discard` or off-screen position).

| Stage / family | Programs | Provider |
|---|---|---|
| Shadow | `shadow`, `shadow_solid`, `shadow_cutout`, `shadow_block`, `shadow_entities`, `shadow_water`, `shadow_lightning` (always disabled) | Iris |
| Mod shadow | `physics_ocean_shadow` | Physics Mod |
| Solid gbuffers | `gbuffers_terrain`, `gbuffers_basic`, `gbuffers_line`, `gbuffers_damagedblock`, `gbuffers_armor_glint`, `gbuffers_beaconbeam`, `gbuffers_skytextured`, `gbuffers_skybasic` (disabled) | Iris |
| Mixed geometry | `gbuffers_entities`, `gbuffers_block`, `gbuffers_hand`, `gbuffers_particles` | Iris |
| Translucent / special | `gbuffers_water`, `gbuffers_textured`, `gbuffers_clouds`, `gbuffers_spidereyes`, `gbuffers_weather`, `gbuffers_lightning` | Iris |
| Distant Horizons | `dh_terrain`, `dh_generic`, `dh_water` | Distant Horizons |
| Voxy | `voxy.json`, `voxy_opaque`, `voxy_translucent` | Voxy |
| Physics ocean | `physics_ocean` | Physics Mod |
| Deferred and composite | `deferred`, `deferred1`, `composite` through `composite14` | Iris |
| Final | `final` | Iris |

`gbuffers_clouds` only renders when `CLOUD_TYPE` is `0` (vanilla clouds); voxel clouds are drawn in `composite`. Loader details: [IrisShaders/docs](https://github.com/IrisShaders/docs).

## Block, Entity, and Dimension IDs

IDs are assigned in `shaders/block.properties`, `shaders/entity.properties`, and `shaders/dimension.properties`. Block IDs must stay unique and are capped at 32767.

| Block ID range | Meaning |
|---|---|
| `10000`-`10999` | Wind-animated land blocks: simple (`100xx`), grounded short/tall (`106xx`/`107xx`), hanging (`108xx`), wall (`109xx`) |
| `11000`-`11999` | Current-animated water blocks (`11100` lava, `11101` lily pad, `11102` water, `11103` Dimensional Doors fluid), corals and rice (`116xx`/`117xx`) |
| `12000`-`12199` | Special and default-on PBR blocks: portals, signs, fire, subsurface plants |
| `12300`-`12520` | Simple PBR: emissive blocks, metals, glass, stone families, ice, snow, soil, concrete |
| `12600`-`13104` | Per-pixel PBR: ores, pyro and redstone emissives, bioluminescent blocks, sculk, crystals |
| `13200`-`13202` | Dimensional Doors fabric and portal blocks |

Notable entity IDs: `10129` lightning bolt, `10130` whole-entity emission, `10131` end crystal, `10132` charged creeper, `10133` boats.

Dimension slots: `world0` is the default for all dimensions (`*`), `world-1` covers the Nether and Undergarden, `world-2` to `world-4` cover Dimensional Doors pockets and Limbo, and `world1` covers the End.

## Optimizations

Performance and resource minimization take priority over maximum quality, consistent with [CONTRIBUTION.md](CONTRIBUTION.md). Volumetric and bloom intermediates run at half resolution, and many programs disable themselves through `shaders.properties` when their feature is off. See [OPTIMIZATION.md](.docs/OPTIMIZATION.md) for measurement guidance.

- Compare the same scene at the same render resolution and profile.
- Change one setting at a time and measure.
- For buffer debugging and profiling, use [GFX Debuggers](https://modrinth.com/mod/gfx-debuggers) with [NVIDIA Nsight Graphics](https://developer.nvidia.com/nsight-graphics) or [RenderDoc](https://renderdoc.org/).

Profiles are practical starting points, not guaranteed FPS targets.

## Project and Compatibility Notes

- **Code priorities**: optimize where possible, minimize resource use, test before submitting, and comment when necessary; see [CONTRIBUTION.md](CONTRIBUTION.md).
- **Current support**: Iris 1.6.10 or later on Minecraft 1.18.2 or later, on Windows and Linux (Intel, AMD, NVIDIA) and Apple M1.
- **Platform caveats**: older AMD drivers may show visual issues; Pojav Launcher is unofficial.
- **Mod compatibility**: open a repository issue with a link to the mod page; code contributions should follow [CONTRIBUTION.md](CONTRIBUTION.md).
- **Known mod issues**: Astrocraft and Nuit have low-priority visual issues.
- **Translations**: the main language file is `en_US.lang` (format v1.1.4). Other `.lang` files must update to match; see [CONTRIBUTION.md](CONTRIBUTION.md) and [TRANSLATORS.md](TRANSLATORS.md).
- **Open work**: see [TODO.md](TODO.md).

## References

- [GLSL 3.30 Specification](https://registry.khronos.org/OpenGL/specs/gl/GLSLangSpec.3.30.pdf)
- [IrisShaders/docs](https://github.com/IrisShaders/docs)
- [CONTRIBUTION.md](CONTRIBUTION.md)