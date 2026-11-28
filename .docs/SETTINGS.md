# Settings Wiki

A reference for the settings available in Super Duper Vanilla (SDV), using the exact English names from `shaders/lang/en_US.lang` and the identifiers from the shader sources.

`shaders/lib/settings.glsl` defines shared settings and their source values. `shaders/shaders.properties` controls the menu, profile inheritance, sliders, and program conditions. Profiles can override those values. Per-dimension values are defined in `shaders/world-X/world.glsl` and documented in [DIMENSION.md](DIMENSION.md).

## Contents

1. [Profiles](#profiles)
2. [Debug](#debug)
3. [Post](#post)
4. [Camera](#camera)
5. [Tonemap](#tonemap)
6. [Lighting](#lighting)
7. [Ray Tracing](#ray-tracing)
8. [Atmospherics](#atmospherics)
9. [World](#world)
10. [PBR](#pbr)
11. [Configuration](#configuration)
12. [Developers](#developers)

## Reading This Wiki

- **UI label** is the localized option name shown in the shader menu.
- **Setting** is the macro or constant identifier used by the shader.
- Toggle states are noted as **On** or **Off**. Defaults and numeric ranges of menu settings are not repeated here, because the shader menu shows them and they are meant to be tuned. Options with fixed choices list what each value does. Only settings that are not exposed in the menu list their values, under [Developers](#developers).
- World-specific settings and non-menu implementation constants are separated into [Developers](#developers); they are not player-facing options unless explicitly listed on a menu page.
- Per-dimension options are player-facing and are documented in [DIMENSION.md](DIMENSION.md); the [Configuration](#configuration) section shows where they sit in the menu. Non-menu implementation constants are separated into [Developers](#developers).

## Profiles

The profile names displayed by the menu are **Potato**, **Low**, **Medium (Default)**, **High**, and **Ultra**. IDs and assignments come from `shaders/shaders.properties`. Each profile inherits from the preceding profile.

| UI label | ID | Added or changed assignments |
|---|---|---|
| Potato | `POTATO` | Sets `CLOUD_TYPE:0`, `ANTI_ALIASING:1`, `PBR_MODE:0`; disables volumetrics, shadows, shadow color/filter, SSAO, rough reflections, previous-frame data, SSR, bloom, and sharpening |
| Low | `LOW` | From Potato: `CLOUD_TYPE:1`, `PBR_MODE:1`, enables shadows/SSR/bloom, `RAYTRACER_STEPS:8`, `RAYTRACER_BISTEPS:2`, `shadowMapResolution:512`, `UNDERWATER_CAUSTICS:0` |
| Medium (Default) | `MEDIUM` | From Low: enables volumetrics, shadow color/filter, rough reflections, SSAO, previous-frame data; sets AA to TAA, ray steps `16`, refinement `4`, shadow resolution `1024`, caustics `1` |
| High | `HIGH` | From Medium: ray steps `32`, shadow resolution `2048`, `PBR_MODE:2` |
| Ultra | `ULTRA` | From High: ray steps `64`, sharpening enabled, shadow resolution `4096`, caustics `2` |

These are profile assignments, not a second set of base defaults. The complete definitions remain in `shaders/shaders.properties`. No profile selects LabPBR (`PBR_MODE:3`); it must be chosen manually.

## Debug

| UI label | Setting | Meaning |
|---|---|---|
| Color mode | `COLOR_MODE` | `0` Off, `1` White Mode, `2` Black Mode, `3` Foliage Mode |
| Noise speed | `NOISE_SPEED` | Temporal noise update speed |

## Post

| UI label | Setting | Meaning |
|---|---|---|
| Outlines | `OUTLINES` | `0` Off, `1` Standard, `2` Dungeons |
| Outline brightness | `OUTLINE_BRIGHTNESS` | Negative is black, positive highlights |
| Outline pixel size | `OUTLINE_PIXEL_SIZE` | Outline pixel size. Adjust to change the thickness of the outlines. |
| Retro filter | `RETRO_FILTER` | Enables retro presentation filter; works best at low render quality |
| Anti aliasing | `ANTI_ALIASING` | `0` OFF, `1` FXAA, `2` TAA, `3` Lite TAA + FXAA |
| Sharpen filter | `SHARPEN_FILTER` | Enables image sharpening; only applies when anti-aliasing is not off |

Anti-aliasing mode `3` runs TAA without projection jitter, followed by FXAA. TAA does not work with custom-resolution screenshots.

## Camera

| UI label | Setting | Meaning |
|---|---|---|
| Depth of field | `DOF` | Enables depth-of-field effect |
| Depth of field strength | `DOF_STRENGTH` | Depth of field strength. |
| Chromatic aberration | `CHROMATIC_ABERRATION` | Enables chromatic aberration |
| Aberration pixel size | `ABERRATION_PIXEL_SIZE` | Chromatic aberration length. Increase for stronger effects. |
| Bloom | `BLOOM` | Enables bloom processing |
| Bloom strength | `BLOOM_STRENGTH` | Bloom brightness. |
| Lens flare | `LENS_FLARE` | Enables lens flare |
| Lens flare strength | `LENS_FLARE_STRENGTH` | Lens flare intensity. |
| Vignette | `VIGNETTE` | Enables vignette |
| Vignette strength | `VIGNETTE_STRENGTH` | Vignette intensity. |
| Motion blur | `MOTION_BLUR` | Enables motion blur |
| Motion blur strength | `MOTION_BLUR_STRENGTH` | Motion blur strength. |

## Tonemap

| UI label | Setting | Meaning |
|---|---|---|
| Contrast | `CONTRAST` | Controls color contrast. |
| Saturation | `SATURATION` | Controls how much color saturation. |
| White point | `WHITE_POINT` | Tonemap whitepoint. |
| Shoulder strength | `SHOULDER_STRENGTH` | Tonemap shoulder strength. |
| Auto exposure | `AUTO_EXPOSURE` | Enables real-time auto exposure; does not work with custom-resolution screenshots |
| Auto exposure speed | `AUTO_EXPOSURE_SPEED` | Higher values adapt faster |
| Exposure | `EXPOSURE` | Controls color exposure. |
| Min exposure | `MINIMUM_EXPOSURE` | Lower values brighten dark scenes more under auto exposure |
| Red tint | `TINT_R` | Red tint value. |
| Green tint | `TINT_G` | Green tint value. |
| Blue tint | `TINT_B` | Blue tint value. |

## Lighting

| UI label | Setting | Meaning |
|---|---|---|
| Shadowmapping | `SHADOW_MAPPING` | Dynamic shadow mapping; disabled mode uses lightmap-based fake shadows |
| Shadowmap color | `SHADOW_COLOR` | Colored data from transparent shadow casters |
| Shadowmap filter | `SHADOW_FILTER` | Noise-based soft shadow filtering; may impact performance |
| Entity shadows | `ENTITY_SHADOWS` | Enables entity shadows |
| Block entity shadows | `BLOCK_ENTITY_SHADOWS` | Enables block-entity shadows |
| Underwater caustics | `UNDERWATER_CAUSTICS` | `0` OFF, `1` Underwater, `2` Full; requires shadow color |
| SSAO | `SSAO` | Screen-space ambient occlusion |
| Ambient lighting | `AMBIENT_LIGHTING` | `0.50` acts like night vision |

### Shadow Map and Light Path

These are shader-menu values backed by `shaders/lib/lighting/shdSampleVar.glsl`.

| UI label | Setting | Meaning |
|---|---|---|
| Shadowmap resolution | `shadowMapResolution` | Shadowmap resolution. |
| Shadowmap distance | `shadowDistance` | Shadowmap distance. |
| Light path angle | `sunPathRotation` | Light path angle. This also affects sky angle. |

## Ray Tracing

| UI label | Setting | Meaning |
|---|---|---|
| SSGI | `SSGI` | Experimental screen-space global illumination; works best with TAA |
| SSR | `SSR` | Screen-space reflections |
| Raytracer steps | `RAYTRACER_STEPS` | Number of steps for ray tracing. Higher values increase quality but reduce performance. |
| Raytracer refinement steps | `RAYTRACER_BISTEPS` | Number of refinement steps for ray tracing. Improves detail in reflections and GI. |
| Rough reflections | `ROUGH_REFLECTIONS` | Roughness-dependent reflections; some AA may hide artifacts |
| Previous frame buffer | `PREVIOUS_FRAME` | Previous-frame color for temporal reflection/GI accumulation; impacts performance |

## Atmospherics

| UI label | Setting | Meaning |
|---|---|---|
| Sun/moon type | `SUN_MOON_TYPE` | `0` Squircle, `1` Round, `2` Vanilla |
| Sun/moon intensity | `SUN_MOON_INTENSITY` | Also affects specular reflections |
| Volumetric lighting | `VOLUMETRIC_LIGHTING` | Enables volumetric lighting |
| Volumetric lighting strength | `VOLUMETRIC_LIGHTING_STRENGTH` | Zero disables its contribution |
| Border fog | `BORDER_FOG` | Covers visible world edges with fog |
| Ground fog strength | `GROUND_FOG_STRENGTH` | The strength of mist/ground fog. |
| Skybox brightness | `SKYBOX_BRIGHTNESS` | Sky box brightness. |

### Cloud Settings

| UI label | Setting | Meaning |
|---|---|---|
| Cloud type | `CLOUD_TYPE` | `0` Vanilla, `1` Voxel |
| Double layered clouds | `DOUBLE_LAYERED_CLOUDS` | Adds a second voxel cloud layer; may use up performance |
| Dynamic clouds | `DYNAMIC_CLOUDS` | Weather-responsive, fading voxel clouds |
| Fade speed | `FADE_SPEED` | Cloud fade speed. |
| 2nd cloud height | `SECOND_CLOUD_HEIGHT` | 2nd layer cloud height, if double vanilla clouds is on. |
| Cloud thickness | `CLOUD_THICKNESS` | Thickness of voxel clouds in blocks |

## World

| UI label | Setting | Meaning |
|---|---|---|
| Terrain animation | `TERRAIN_ANIMATION` | Terrain/foliage animation |
| Water animation | `WATER_ANIMATION` | Water animation |
| Weather animation | `WEATHER_ANIMATION` | Rain/weather animation |
| Timelapse mode | `TIMELAPSE_MODE` | `0` OFF, `1` Fragment, `2` Full |
| Wind speed | `WIND_SPEED` | Adjust wind speed. Affects plants, swinging objects, and weather. Increases the animation speed. |
| Current speed | `CURRENT_SPEED` | Adjust liquid and under water flow speed. Affects underwater plants and liquids. Increases the animation speed. |
| Wind frequency | `WIND_FREQUENCY` | Adjust wind frequency. Affects plants, swinging objects, and weather. Increases the animation change frequency. |
| Current frequency | `CURRENT_FREQUENCY` | Adjust liquid and under water flow frequency. Affects underwater plants and liquids. Increases the animation change frequency. |
| World curvature | `WORLD_CURVATURE` | Enables world curvature |
| World curvature size | `WORLD_CURVATURE_SIZE` | World curvature size. |

Timelapse mode `1` applies fragment-level time behavior for water normals and sky; mode `2` also applies it to waves. Vanilla clouds, the skybox, and sun/moon are not affected.

## PBR

| UI label | Setting | Meaning |
|---|---|---|
| PBR mode | `PBR_MODE` | `0` OFF, `1` Basic PBR, `2` Integrated PBR, `3` Lab PBR 1.3 |
| Specular highlights | `SPECULAR_HIGHLIGHTS` | Approximate sun reflections |
| Enviro PBR materials | `ENVIRONMENT_PBR` | Environment-dependent material response (rain wetness) |
| Subsurface scattering | `SUBSURFACE_SCATTERING` | Scattering on thin/organic materials |
| Emissive intensity | `EMISSIVE_INTENSITY` | Requires PBR; does not affect lightmaps |
| Normal strength | `NORMAL_STRENGTH` | Applies to LabPBR normal maps and auto-generated normals |
| Slope normals | `SLOPE_NORMALS` | Sharper slope normals for parallax occlusion surfaces; disable with high-resolution packs that have normal maps |
| Directional lightmaps | `DIRECTIONAL_LIGHTMAPS` | Requires generated or PBR normals |
| Directional lightmaps strength | `DIRECTIONAL_LIGHTMAP_STRENGTH` | Directional lightmap strength. Effective if directional lightmaps is enabled. |

Integrated PBR infers materials from vanilla albedo textures; mode `2` also gives rough-reflection smoothness to stone, soil, and similar blocks when rough reflections are on. LabPBR (mode `3`) requires a resource pack with LabPBR 1.3 materials.

### Parallax Occlusion

| UI label | Setting | Meaning |
|---|---|---|
| Parallax occlusion | `PARALLAX_OCCLUSION` | Requires LabPBR and a LabPBR resource pack |
| Parallax depth | `PARALLAX_DEPTH` | Sets the maximum depth for parallax occlusion mapping. Higher values increase the effect. |
| Parallax steps | `PARALLAX_STEPS` | Number of steps for parallax occlusion mapping. More steps improve quality but reduce performance. |
| Parallax shadows | `PARALLAX_SHADOW` | Self-shadowing for parallax surfaces |
| Parallax shadow steps | `PARALLAX_SHADOW_STEPS` | Number of steps for parallax shadowing. Higher values improve shadow detail. |

### iPBR Material Subpages

The iPBR page also holds the generated-normal settings:

| UI label | Setting | Meaning |
|---|---|---|
| Auto gen normals | `NORMAL_GENERATION` | Generates normals from albedo; disabled with LabPBR; works mostly on vanilla-style packs |
| Auto gen normal resolution | `NORMAL_GENERATION_RESOLUTION` | Minor performance effect |

#### Water Material Settings

| UI label | Setting | Meaning |
|---|---|---|
| Water noise | `WATER_NOISE` | Varies water brightness with noise |
| Water brightness | `WATER_BRIGHTNESS` | Lower is deeper color |
| Water normalmap | `WATER_NORMAL` | Water surface normals |
| Water normalmap blur size | `WATER_BLUR_SIZE` | Smaller is more defined waves |
| Water normalmap depth size | `WATER_DEPTH_SIZE` | Smaller is deeper |
| Water tile size | `WATER_TILE_SIZE` | Sets the tiling scale for water textures. |
| Water absorption | `WATER_STYLIZE_ABSORPTION` | Depth-based stylized absorption |
| Water foam | `WATER_FOAM` | Foam at solid surfaces, including entities |
| Flat water albedo | `WATER_FLAT` | Flat water albedo |

#### Lava Material Settings

| UI label | Setting | Meaning |
|---|---|---|
| Lava brightness | `LAVA_BRIGHTNESS` | Adjusts the brightness of lava materials. |
| Lava noise | `LAVA_NOISE` | Lava brightness noise |
| Lava tile size | `LAVA_TILE_SIZE` | Sets the tiling scale for lava textures. |

#### Sculk Material Settings

| UI label | Setting | Meaning |
|---|---|---|
| Sculk brightness | `SCULK_BRIGHTNESS` | Adjusts the brightness of sculk materials. |
| Sculk noise | `SCULK_NOISE` | Sculk emission noise |
| Sculk tile size | `SCULK_TILE_SIZE` | Sets the tiling scale for sculk textures. |

## Configuration

The Configuration screen holds the per-dimension settings and the block light page. The labels below are the `en_US.lang` labels. Option IDs and what each option does are in [DIMENSION.md](DIMENSION.md).

```
Configuration
├── Vanilla dimensions
│   ├── Overworld settings
│   ├── Nether settings
│   └── End settings
├── Dimensional Doors
│   ├── Dimdoors: Pockets settings
│   ├── Dimdoors: Limbo settings
│   └── Dimdoors: Personal pockets settings
├── Wildcard dimension settings
└── Block light settings
```

### Dimension Screens

Every dimension has the same screens and the same options, so changing a dimension means changing values, not hunting for different options. The wildcard screen applies to any dimension not listed in `dimension.properties`.

| Screen | Contents |
|---|---|
| Features | Skybox, Clouds, Weather, Day cycle, Real skylight, Directional light, Stars, Aether, Sky ground, Vanilla fog color (each On or Off) |
| Basic | Skylight amount, Celestial body, Celestial size, Vanilla fog mode, Vanilla fog strength |
| Day, Night, Twilight | Light red, green, blue, and intensity; Sky red, green, blue, and intensity; Total fog density; Vertical fog density; Star intensity. Used when Day cycle is On |
| Constant | The same settings, used at all times when Day cycle is Off. Its star intensity uses the Constant value |

Option tooltips say when an option is used. Options of a disabled feature stay visible, because the menu cannot hide them conditionally. For example, the Day, Night, and Twilight screens have no effect when Day cycle is Off.


### Block Light Page

| UI label | Setting | Meaning |
|---|---|---|
| Block light red | `BLOCKLIGHT_R` | Red channel for block light color. |
| Block light green | `BLOCKLIGHT_G` | Green channel for block light color. |
| Block light blue | `BLOCKLIGHT_B` | Blue channel for block light color. |
| Block light intensity | `BLOCKLIGHT_I` | Intensity for block light color. |

Dimension options are documented in [DIMENSION.md](DIMENSION.md).

## Developers

This section documents source-side values that do not appear as player options. They are listed for implementation work and are intentionally hidden from the shader menu.

### Per-Dimension Settings

The former developer-only world flags (forced-off clouds, weather, and day cycle, sky ground, Aether, custom skylight, stars, and vanilla fog color) are now regular options on each dimension's Configuration screens. Option IDs, resolution, and defaults per dimension are in [DIMENSION.md](DIMENSION.md). Only `WORLD_ID` and `WORLD_PREFIX` remain source-level identifiers that don't appear in the menu.

The Dimensional Doors world files are credited to Kawwabi.

### Shadow Sampling Constants

`shaders/lib/lighting/shdSampleVar.glsl` defines the shadow menu settings (documented under [Lighting](#lighting)) and the implementation constants below.

| Constant | Value | Status |
|---|---:|---|
| `shadowHardwareFiltering` | `true` | Internal constant |
| `shadowDistanceRenderMul` | `1.0` | Fixed internal constant |
| `entityShadowDistanceMul` | `0.5` | Internal constant; entity shadows use half the shadow distance |
| `shadowMapPixelSize` | Derived | Reciprocal of `shadowMapResolution` |
| `shadowDistanceInv` | Derived | Reciprocal of `shadowDistance` |

### Other Internal Constants

| Constant | Value | Meaning |
|---|---:|---|
| `ALPHA_THRESHOLD` | `0.1` | Manual alpha-test cutoff used by the programs (alpha testing is disabled in `shaders.properties`) |

### Physics Mod Constants

`PHYSICS_OCEAN_SUPPORT` is enabled in `settings.glsl`. These source constants are consumed by the Physics Mod ocean shaders; they are not menu controls.

| Constant | Default | Meaning |
|---|---:|---|
| `PHYSICS_ITERATIONS_OFFSET` | `13` | Wave iteration offset |
| `PHYSICS_DRAG_MULT` | `0.048` | Wave position drag |
| `PHYSICS_XZ_SCALE` | `0.035` | Horizontal coordinate scale |
| `PHYSICS_TIME_MULTIPLICATOR` | `0.45` | Simulation time scaling |
| `PHYSICS_W_DETAIL` | `0.75` | Wave detail weighting |
| `PHYSICS_FREQUENCY` | `6.0` | Base wave frequency |
| `PHYSICS_SPEED` | `2.0` | Base wave speed |
| `PHYSICS_WEIGHT` | `0.8` | Wave contribution weight |
| `PHYSICS_FREQUENCY_MULT` | `1.18` | Frequency multiplier per iteration |
| `PHYSICS_SPEED_MULT` | `1.07` | Speed multiplier per iteration |
| `PHYSICS_ITER_INC` | `12.0` | Iteration increment |
| `PHYSICS_NORMAL_STRENGTH` | `0.6` | Ocean normal strength |

### Derived Values

The following are computed from settings rather than independently adjustable controls: `blockLightColor`, `cloudDepthInverse`, `cloudCenterDepth`, `cloudHeight` (fixed at `195` plus half the cloud thickness), `sunMoonIntensitySqrd`, `skyBoxIntensitySqrd`, `worldCurvatureInv`, and `waterTileSizeInv`.

### Source Map

| File | Settings responsibility |
|---|---|
| `shaders/lib/settings.glsl` | Shared feature toggles, numeric settings, and Physics Mod constants |
| `shaders/shaders.properties` | Menu registration, profiles, slider lists, render-target size, program enable rules, custom uniforms |
| `shaders/lang/en_US.lang` | Exact English names, descriptions, and enum labels shown to users |
| `shaders/lib/lighting/shdSampleVar.glsl` | Shadow-map settings and derived shadow values |
| `shaders/world-X/world.glsl` | Per-dimension options; see [DIMENSION.md](DIMENSION.md) |
| `shaders/lib/dimension/` | World resolver and the sky, light, fog, and star adapters |