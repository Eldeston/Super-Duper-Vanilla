# Super Duper Vanilla Shader Documentation

| Metadata | Value |
|---|---|
| Version | 1.3.9-beta.4 |
| Current shader loader | Iris |
| Legacy support | OptiFine support was dropped in v1.3.7 |
| GLSL | 3.3 Compatibility; `gbuffers_line` uses 3.3 Core |

Super Duper Vanilla (SDV) is a high performance Minecraft shader pack. This document summarizes its features, controls, rendering architecture, buffer system, programs, and optimization approach.

## Features

### Materials and Surface Detail

- **Physically Based Rendering (PBR)** with a metallic workflow and GGX microfacet specular shading.
- PBR modes for integrated materials and resource-pack materials; resource PBR expects LabPBR-compatible data.
- Normal maps, optional generated/slope normals, parallax occlusion mapping, emissive materials, and subsurface scattering.
- Environment-dependent material response, including water, lava, and sculk styling.

### Lighting

- Dynamic shadow mapping, configurable shadow filtering and colored shadows.
- Optional entity and block-entity shadows.
- Screen-space ambient occlusion (SSAO), screen-space reflections (SSR), and experimental screen-space global illumination (SSGI; disabled by default).
- Directional lightmaps, ambient-light control, and underwater caustics.

### Atmosphere and World Effects

- Sky and sun/moon appearance, fog, border fog, ground fog, and volumetric lighting.
- Multiple cloud modes, optional double cloud layers, and weather-responsive cloud behavior.
- Terrain, water, and weather animation with wind/current controls, timelapse mode, and optional world curvature.

### Post-Processing and Presentation

- Anti-aliasing: FXAA, TAA, both, or disabled.
- Motion blur and depth of field.
- Bloom, lens flare, auto exposure, tone mapping, color tint/saturation/contrast, and vignette.
- Outlines, optional retro filtering, chromatic aberration, and optional sharpening.

Distant Horizons, Voxy, and Physics Mod integrations are present in the shader sources. See the program matrix below for which integration supplies each program family.

## Settings

Settings have several source layers:

| Source | Defines |
|---|---|
| [`shaders/lib/settings.glsl`](shaders/lib/settings.glsl) | Shared feature toggles, numeric defaults, and their value domains |
| [`shaders/shaders.properties`](shaders/shaders.properties) | Visible menu pages, profiles, sliders, program conditions, and target sizing |
| [`shaders/lang/en_US.lang`](shaders/lang/en_US.lang) | Exact English menu labels and enum display names |
| [`shaders/lib/lighting/shdSampleVar.glsl`](shaders/lib/lighting/shdSampleVar.glsl) | Shadow-map controls and internal sampling constants |
| `shaders/world-X/world.glsl` | Per-dimension world flags and lighting/fog defaults |

### Profiles

The main settings screen provides Potato, Low, Medium (Default), High, and Ultra. IDs are `POTATO`, `LOW`, `MEDIUM`, `HIGH`, and `ULTRA`; each inherits from the previous profile. Potato disables shadow rendering; Low through Ultra select shadow-map resolutions of 512, 1024, 2048, and 4096. Profiles also set feature toggles, AA mode, ray-tracing step counts, cloud type, and underwater caustics.

### Menu Navigation

The UI proceeds through Debug, Post, Lighting, Atmospherics, World, PBR, and Configuration. Post contains Camera settings and Tonemap settings; Lighting contains Ray tracing settings; Atmospherics contains Cloud settings; PBR contains POM and iPBR material subpages; Configuration contains Overworld, Nether, End, and Block light pages. The exact displayed English names are in `shaders/lang/en_US.lang`.

### Settings Highlights

| Group | Examples |
|---|---|
| Post and camera | Outlines, Anti aliasing (`0` Off, `1` FXAA, `2` TAA, `3` Lite TAA + FXAA), DOF, bloom, lens flare, motion blur |
| Tonemap | Contrast, saturation, white point, shoulder strength, exposure, minimum exposure, RGB tint |
| Lighting | Shadowmapping, Shadowmap color/filter, entity and block entity shadows, underwater caustics, SSAO, ambient lighting |
| Ray tracing | SSGI, SSR, Raytracer steps/refinement, rough reflections, previous frame buffer |
| Atmospherics and world | Sun/moon type/intensity, volumetrics, fog, clouds, animations, timelapse, wind/current, curvature |
| PBR and materials | PBR mode (`0` Off, `1` Integrated PBR, `2` Lab PBR 1.3), normals, POM, water/lava/sculk settings |
| Configuration | Per-dimension light, sky, fog, and block-light colors |

`shadowMapResolution` defaults to 1024 and is available from 512 to 8192 in steps of 512; `shadowDistance` defaults to 128 blocks; `sunPathRotation` defaults to 30 degrees. Profile shadow resolutions go up to 4096.

### Developer-Hidden World Settings

Many `world.glsl` values are intentionally not menu options. These include `WORLD_ID`, `WORLD_LIGHT`, `WORLD_SUN_MOON`, `WORLD_SUN_MOON_SIZE`, `FORCE_DISABLE_CLOUDS`, `FORCE_DISABLE_WEATHER`, `FORCE_DISABLE_DAY_CYCLE`, `WORLD_SKY_GROUND`, `WORLD_AETHER`, `WORLD_CUSTOM_SKYLIGHT`, `WORLD_STARS`, and `WORLD_VANILLA_FOG_COLOR`. `WORLDn1_VANILLA_FOGCOLI` appears as Nether Sky intensity when defined; the optional `WORLD0_VANILLA_FOGCOLI` and `WORLD1_VANILLA_FOGCOLI` remain source-side values.

Menu options use the shader settings UI. Editing source macros or world values requires reloading shaders so programs recompile.

## Architecture

The frame follows five broad stages:

```text
+-------------------+    +---------+    +----------+    +--------------------+    +-------+
| Shadow programs   | -> | Gbuffers| -> | Deferred | -> | Composite programs | -> | Final |
+-------------------+    +---------+    +----------+    +--------------------+    +-------+
```

1. **Shadow programs** render scene depth from the light view and optionally colored shadow data.
2. **Gbuffers** render geometry, forward shading, and material data for later lighting.
3. **Deferred programs** process screen-space data, including SSAO and deferred shading.
4. **Composite programs** execute in order with explicit read/write dependencies; not every pass reads only the previous pass's output.
5. **Final** applies final presentation filters and writes the image to the screen.

SDV uses a hybrid forward/deferred design: geometry-specific shading remains in Gbuffers where useful, while screen-space work and post-processing consume shared render targets. There are 13 composite slots: `composite` (slot 0) through `composite12`. `composite1` is currently disabled.

| Composite program(s) | Main responsibility |
|---|---|
| `composite` (0) | Deferred and transparent complex shading |
| `composite1` | Disabled no-op |
| `composite2`-`composite3` | Half-resolution volumetrics, then upsample/combine |
| `composite4` | TAA and temporal history |
| `composite5` | FXAA when selected |
| `composite6`-`composite7` | Motion blur and depth of field |
| `composite8`-`composite11` | Bloom downsample/blur/upsampling and lens flare |
| `composite12` | Bloom application, exposure, tonemapping, vignette, grading, dithering |

Dimension-specific shader overrides and lighting macros are organized under `shaders/world-X/`.

## Buffers

The shader uses six color targets. `colortex0` is configured at half width and half height, so it has one quarter the pixel count of a full-resolution target. It is reused for volumetrics and bloom.

| Target | Format | Main payload and lifetime |
|---|---|---|
| `colortex0` | `R11F_G11F_B10F` | Half-resolution volumetrics, then bloom intermediates; cloud texture may also be bound to this sampler in selected programs |
| `colortex1` | `RGB16_SNORM` | Surface normals read by deferred shading |
| `colortex2` | `RGBA8` | Albedo in RGB; SSAO data in alpha after deferred processing |
| `colortex3` | `RGB8` | Material data for deferred shading, later FXAA/final post-processed color |
| `colortex4` | `R11F_G11F_B10F` | Main HDR scene color through shading and post-processing |
| `colortex5` | `RGBA16F` | Conditional temporal history and auto-exposure data |

The buffer lifecycle is deliberately multipurposed: `colortex3` changes from material data to post-processed color, while `colortex0` changes from half-resolution volumetrics to bloom intermediates. Depth/shadow attachments include `depthtex0`, `depthtex1`, `shadowtex0`, optional `shadowtex1`, and `shadowcolor0` when colored shadows are enabled.

## Programs

Program classifications describe shading complexity: **Complex** programs perform more complete PBR/lighting work; **Basic** programs use reduced shading; **Simple** programs handle lightweight rendering; **Disabled** programs are discarded or disabled by configuration.

The legacy documentation called the last program-table column “Usage.” The entries actually identify the loader or mod integration that provides a program, so this summary uses **Provider / Loader Availability**. OptiFine entries are historical: current SDV support is Iris-only.

| Stage / family | Example programs | Purpose | Provider / loader availability |
|---|---|---|---|
| Shadow: base | `shadow`, `shadow_solid`, `shadow_cutout` | Main, solid, and alpha-tested shadow rendering | Iris; OptiFine (legacy entry) |
| Shadow: extensions | `shadow_block`, `shadow_entities`, `shadow_water`, `shadow_lightning` | Block/entity/water/lightning shadow paths | Iris |
| Mod shadow | `physics_ocean_shadow` | Physics-ocean shadow rendering | Physics Mod |
| Solid Gbuffers | `gbuffers_terrain`, `gbuffers_basic`, `gbuffers_line`, `gbuffers_skybasic`, `gbuffers_skytextured`, `gbuffers_damagedblock`, `gbuffers_armor_glint`, `gbuffers_beaconbeam` | Terrain, basic geometry, sky, damage overlay, and special materials | Iris; OptiFine is a legacy entry |
| Distant Horizons | `dh_terrain`, `dh_generic`, `dh_water` | Distant terrain, generic geometry, and water | Distant Horizons integration |
| Mixed geometry | `gbuffers_entities`, `gbuffers_block`, `gbuffers_hand`, `gbuffers_particles` | Entities, block entities, hand, and particles | Iris; entities/block/hand have legacy OptiFine entries; particles are Iris |
| Translucent/special Gbuffers | `gbuffers_clouds`, `gbuffers_textured`, `gbuffers_spidereyes`, `gbuffers_water`, `gbuffers_weather`, `gbuffers_lightning` | Clouds, mapped textures, water, weather, glow, and lightning | Iris; several have legacy OptiFine entries |
| Mod ocean | `physics_ocean` | Physics-mod ocean geometry | Physics Mod |
| Deferred and composites | `deferred`, `deferred1`, `composite` through `composite12` | Deferred screen-space work and post-processing | Iris; OptiFine entries are historical |

`gbuffers_skybasic` is classified as disabled in the legacy program table. `composite1` is explicitly disabled by current configuration. The detailed loader specifications are available from [IrisShaders/docs](https://github.com/IrisShaders/docs) and the [OptiFine shader specification](https://github.com/sp614x/optifine/blob/master/OptiFineDoc/doc/shaders.txt#L447).

## Optimizations

Performance and resource minimization take priority over maximum quality. Current structural optimizations include reusing the six color targets and running volumetrics/bloom intermediates at half resolution.

For reliable tuning:

- Compare the same scene at the same render resolution and profile.
- Change one setting at a time; measure rather than relying on generic FPS estimates.
- Reduce `shadowMapResolution` when shadow-map cost or memory is the bottleneck.
- Disable optional effects such as SSR, volumetrics, bloom, DOF, or motion blur when needed.
- Keep SSGI off for performance builds; it is experimental and unoptimized.

The `POTATO` through `ULTRA` shader profiles are practical starting points, not guaranteed FPS targets. Actual cost depends on hardware, scene, resolution, and enabled effects.

## Project and Compatibility Notes

- **Code priorities**: minimize resources and favor performance; keep main program code simple and follow [`CONTRIBUTION.md`](CONTRIBUTION.md).
- **World macros**: `WORLD_ID`, `WORLD_LIGHT`, `WORLD_SUN_MOON`, and `WORLD_SUN_MOON_SIZE` define per-dimension lighting behavior. Their values are implementation-oriented and are not presented as general user settings.
- **Known mod issues**: archived notes list visual bugs with Astrocraft and Nuit, both low priority.
- **Historical backlog**: earlier pending/current items covered shadow-model and sky fixes, translucent detection, world lighting, iPBR/POM, DOF, block IDs, day/night transitions, uniform/code cleanup, bit packing, clouds/fog/water/tonemapping, Distant Horizons depth, menu UI, Voxy, voxel clouds, lighting separation, and albedo. Treat these as historical notes, not verified current tasks.
- **Completed items in the historical notes**: OptiFine support was abandoned; alpha testing, Distant Horizons generic rendering, dragon beam, FXAA, portal depth, subsurface scattering, and shadow filtering had been marked done.

## References

- [GLSL 3.30 Specification](https://registry.khronos.org/OpenGL/specs/gl/GLSLangSpec.3.30.pdf)
- [IrisShaders/docs](https://github.com/IrisShaders/docs)
- [OptiFine shader specification](https://github.com/sp614x/optifine/blob/master/OptiFineDoc/doc/shaders.txt#L447)
- [`CONTRIBUTION.md`](CONTRIBUTION.md)

## Detailed Documentation

This file is the documentation front page. Topic-specific references are maintained in `.docs/`:

| Topic | Reference |
|---|---|
| Pipeline overview and stages | [ARCHITECTURE.md](.docs/ARCHITECTURE.md) |
| Programs and provider/loader availability | [PROGRAMS.md](.docs/PROGRAMS.md) |
| Buffer lanes and lifetimes | [BUFFERS.md](.docs/BUFFERS.md) |
| Feature implementations | [FEATURES.md](.docs/FEATURES.md) |
| Settings catalog | [SETTINGS.md](.docs/SETTINGS.md) |
| Profiling and optimization | [OPTIMIZATION.md](.docs/OPTIMIZATION.md) |
| Historical project notes | [LEGACY.md](.docs/LEGACY.md) |
