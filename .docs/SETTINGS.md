# Settings Wiki

A reference for the settings available in Super Duper Vanilla (SDV), using the exact English names from `shaders/lang/en_US.lang` and the identifiers/defaults from the shader sources.

`shaders/lib/settings.glsl` defines shared settings and source defaults. `shaders/shaders.properties` controls the menu, profile inheritance, sliders, and program conditions. Profiles can override the source defaults. Per-dimension values are defined in `shaders/world-X/world.glsl` and documented in [DIMENSION.md](DIMENSION.md).

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
- **Default** is the value in the source file before a selected profile overrides it.
- Toggle states are noted as **On** or **Off**. Numeric domains are the values declared for the shader menu/source setting.
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

| UI label | Setting | Default | Values / meaning |
|---|---|---:|---|
| Color mode | `COLOR_MODE` | `0` | `0` Off, `1` White Mode, `2` Black Mode, `3` Foliage Mode |
| Noise speed | `NOISE_SPEED` | `8` | `2, 4, 8, 16, 32`; temporal noise update speed |

## Post

| UI label | Setting | Default | Values / meaning |
|---|---|---:|---|
| Outlines | `OUTLINES` | `2` | `0` Off, `1` Standard, `2` Dungeons |
| Outline brightness | `OUTLINE_BRIGHTNESS` | `1.00` | `-1.00` to `1.00`, step `0.05`; negative is black, positive highlights |
| Outline pixel size | `OUTLINE_PIXEL_SIZE` | `1` | `1, 2, 4, 8, 16, 32, 64` |
| Retro filter | `RETRO_FILTER` | Off | Enables retro presentation filter; works best at low render quality |
| Anti aliasing | `ANTI_ALIASING` | `2` | `0` OFF, `1` FXAA, `2` TAA, `3` Lite TAA + FXAA |
| Sharpen filter | `SHARPEN_FILTER` | Off | Enables image sharpening; only applies when anti-aliasing is not off |

Anti-aliasing mode `3` runs TAA without projection jitter, followed by FXAA. TAA does not work with custom-resolution screenshots.

## Camera

| UI label | Setting | Default | Values / meaning |
|---|---|---:|---|
| Depth of field | `DOF` | Off | Enables depth-of-field effect |
| Depth of field strength | `DOF_STRENGTH` | `1` | `1, 2, 3, 4` |
| Chromatic aberration | `CHROMATIC_ABERRATION` | Off | Enables chromatic aberration |
| Aberration pixel size | `ABERRATION_PIXEL_SIZE` | `4` | `1, 2, 4, 8, 16` |
| Bloom | `BLOOM` | On | Enables bloom processing |
| Bloom strength | `BLOOM_STRENGTH` | `0.75` | `0.00` to `1.00`, step `0.05` |
| Lens flare | `LENS_FLARE` | On | Enables lens flare |
| Lens flare strength | `LENS_FLARE_STRENGTH` | `1.00` | `0.00` to `2.00`, step `0.05` |
| Vignette | `VIGNETTE` | Off | Enables vignette |
| Vignette strength | `VIGNETTE_STRENGTH` | `1.00` | `0.00` to `2.00`, step `0.05` |
| Motion blur | `MOTION_BLUR` | Off | Enables motion blur |
| Motion blur strength | `MOTION_BLUR_STRENGTH` | `1.00` | `0.00` to `2.00`, step `0.05` |

## Tonemap

| UI label | Setting | Default | Values / meaning |
|---|---|---:|---|
| Contrast | `CONTRAST` | `1.00` | `0.00` to `2.00`, step `0.05` |
| Saturation | `SATURATION` | `1.00` | `0.00` to `2.00`, step `0.05` |
| White point | `WHITE_POINT` | `2.0` | `0.0` to `4.0`, step `0.1` |
| Shoulder strength | `SHOULDER_STRENGTH` | `0.00` | `0.00` to `1.00`, step `0.05` |
| Auto exposure | `AUTO_EXPOSURE` | Off | Enables real-time auto exposure; does not work with custom-resolution screenshots |
| Auto exposure speed | `AUTO_EXPOSURE_SPEED` | `1.00` | `0.00` to `2.00`, step `0.05`; higher values adapt faster |
| Exposure | `EXPOSURE` | `1.00` | `0.00` to `2.00`, step `0.05` |
| Min exposure | `MINIMUM_EXPOSURE` | `0.10` | `0.10` to `0.90`, step `0.10`; lower values brighten dark scenes more under auto exposure |
| Red tint | `TINT_R` | `255` | `3` to `255`, step `3` |
| Green tint | `TINT_G` | `255` | `3` to `255`, step `3` |
| Blue tint | `TINT_B` | `255` | `3` to `255`, step `3` |

## Lighting

| UI label | Setting | Default | Values / meaning |
|---|---|---:|---|
| Shadowmapping | `SHADOW_MAPPING` | On | Dynamic shadow mapping; disabled mode uses lightmap-based fake shadows |
| Shadowmap color | `SHADOW_COLOR` | On | Colored data from transparent shadow casters |
| Shadowmap filter | `SHADOW_FILTER` | On | Noise-based soft shadow filtering; may impact performance |
| Entity shadows | `ENTITY_SHADOWS` | On | Enables entity shadows |
| Block entity shadows | `BLOCK_ENTITY_SHADOWS` | On | Enables block-entity shadows |
| Underwater caustics | `UNDERWATER_CAUSTICS` | `1` | `0` OFF, `1` Underwater, `2` Full; requires shadow color |
| SSAO | `SSAO` | On | Screen-space ambient occlusion |
| Ambient lighting | `AMBIENT_LIGHTING` | `0.05` | `0.00` to `0.50`, step `0.01`; `0.50` acts like night vision |

### Shadow Map and Light Path

These are shader-menu values backed by `shaders/lib/lighting/shdSampleVar.glsl`.

| UI label | Setting | Default | Values |
|---|---|---:|---|
| Shadowmap resolution | `shadowMapResolution` | `1024` | `512` to `8192`, step `512` |
| Shadowmap distance | `shadowDistance` | `128.0` blocks | `32.0` to `1024.0`, step `32.0` |
| Light path angle | `sunPathRotation` | `30.0` degrees | `-60.0` to `60.0`, step `5.0` |

## Ray Tracing

| UI label | Setting | Default | Values / meaning |
|---|---|---:|---|
| SSGI | `SSGI` | Off | Experimental screen-space global illumination; works best with TAA |
| SSR | `SSR` | On | Screen-space reflections |
| Raytracer steps | `RAYTRACER_STEPS` | `16` | `2, 4, 8, 16, 32, 64, 128` |
| Raytracer refinement steps | `RAYTRACER_BISTEPS` | `4` | `0, 2, 4, 6, 8` |
| Rough reflections | `ROUGH_REFLECTIONS` | On | Roughness-dependent reflections; some AA may hide artifacts |
| Previous frame buffer | `PREVIOUS_FRAME` | On | Previous-frame color for temporal reflection/GI accumulation; impacts performance |

## Atmospherics

| UI label | Setting | Default | Values / meaning |
|---|---|---:|---|
| Sun/moon type | `SUN_MOON_TYPE` | `0` | `0` Squircle, `1` Round, `2` Vanilla |
| Sun/moon intensity | `SUN_MOON_INTENSITY` | `4` | `0` through `8`; also affects specular reflections |
| Volumetric lighting | `VOLUMETRIC_LIGHTING` | On | Enables volumetric lighting |
| Volumetric lighting strength | `VOLUMETRIC_LIGHTING_STRENGTH` | `0.50` | `0.00` to `1.00`, step `0.05`; zero disables its contribution |
| Border fog | `BORDER_FOG` | On | Covers visible world edges with fog |
| Ground fog strength | `GROUND_FOG_STRENGTH` | `0.50` | `0.00` to `1.00`, step `0.05` |
| Skybox brightness | `SKYBOX_BRIGHTNESS` | `1.00` | `0.00` to `2.00`, step `0.05` |

### Cloud Settings

| UI label | Setting | Default | Values / meaning |
|---|---|---:|---|
| Cloud type | `CLOUD_TYPE` | `1` | `0` Vanilla, `1` Voxel |
| Double layered clouds | `DOUBLE_LAYERED_CLOUDS` | On | Adds a second voxel cloud layer; may use up performance |
| Dynamic clouds | `DYNAMIC_CLOUDS` | On | Weather-responsive, fading voxel clouds |
| Fade speed | `FADE_SPEED` | `0.10` | `0.00` to `4.00`, step `0.05` |
| 2nd cloud height | `SECOND_CLOUD_HEIGHT` | `128.0` | `0.0` to `256.0`, step `4.0` |
| Cloud thickness | `CLOUD_THICKNESS` | `8.0` | `4.0, 6.0, 8.0, 10.0, 12.0`; thickness of voxel clouds in blocks |

## World

| UI label | Setting | Default | Values / meaning |
|---|---|---:|---|
| Terrain animation | `TERRAIN_ANIMATION` | On | Terrain/foliage animation |
| Water animation | `WATER_ANIMATION` | On | Water animation |
| Weather animation | `WEATHER_ANIMATION` | On | Rain/weather animation |
| Timelapse mode | `TIMELAPSE_MODE` | `0` | `0` OFF, `1` Fragment, `2` Full |
| Wind speed | `WIND_SPEED` | `1.00` | `0.00` to `4.00`, step `0.05` |
| Current speed | `CURRENT_SPEED` | `1.00` | `0.00` to `4.00`, step `0.05` |
| Wind frequency | `WIND_FREQUENCY` | `1.00` | `0.00` to `4.00`, step `0.05` |
| Current frequency | `CURRENT_FREQUENCY` | `1.00` | `0.00` to `4.00`, step `0.05` |
| World curvature | `WORLD_CURVATURE` | Off | Enables world curvature |
| World curvature size | `WORLD_CURVATURE_SIZE` | `256` | `-4096, -2048, -1024, -512, -256, -128, 128, 256, 512, 1024, 2048, 4096` |

Timelapse mode `1` applies fragment-level time behavior for water normals and sky; mode `2` also applies it to waves. Vanilla clouds, the skybox, and sun/moon are not affected.

## PBR

| UI label | Setting | Default | Values / meaning |
|---|---|---:|---|
| PBR mode | `PBR_MODE` | `1` | `0` OFF, `1` Basic PBR, `2` Integrated PBR, `3` Lab PBR 1.3 |
| Specular highlights | `SPECULAR_HIGHLIGHTS` | On | Approximate sun reflections |
| Enviro PBR materials | `ENVIRONMENT_PBR` | On | Environment-dependent material response (rain wetness) |
| Subsurface scattering | `SUBSURFACE_SCATTERING` | On | Scattering on thin/organic materials |
| Emissive intensity | `EMISSIVE_INTENSITY` | `8` | `2, 4, 8, 16, 32`; requires PBR; does not affect lightmaps |
| Normal strength | `NORMAL_STRENGTH` | `1.00` | `0.00` to `1.00`, step `0.05`; applies to LabPBR normal maps and auto-generated normals |
| Slope normals | `SLOPE_NORMALS` | Off | Sharper slope normals for parallax occlusion surfaces; disable with high-resolution packs that have normal maps |
| Directional lightmaps | `DIRECTIONAL_LIGHTMAPS` | Off | Requires generated or PBR normals |
| Directional lightmaps strength | `DIRECTIONAL_LIGHTMAP_STRENGTH` | `1.00` | `0.00` to `1.00`, step `0.05` |

Integrated PBR infers materials from vanilla albedo textures; mode `2` also gives rough-reflection smoothness to stone, soil, and similar blocks when rough reflections are on. LabPBR (mode `3`) requires a resource pack with LabPBR 1.3 materials.

### Parallax Occlusion

| UI label | Setting | Default | Values / meaning |
|---|---|---:|---|
| Parallax occlusion | `PARALLAX_OCCLUSION` | Off | Requires LabPBR and a LabPBR resource pack |
| Parallax depth | `PARALLAX_DEPTH` | `0.25` | `0.00` to `0.50`, step `0.05` |
| Parallax steps | `PARALLAX_STEPS` | `128` | `16, 32, 64, 128, 256, 512` |
| Parallax shadows | `PARALLAX_SHADOW` | On | Self-shadowing for parallax surfaces |
| Parallax shadow steps | `PARALLAX_SHADOW_STEPS` | `32` | `16, 32, 64, 128, 256, 512` |

### iPBR Material Subpages

The iPBR page also holds the generated-normal settings:

| UI label | Setting | Default | Values / meaning |
|---|---|---:|---|
| Auto gen normals | `NORMAL_GENERATION` | Off | Generates normals from albedo; disabled with LabPBR; works mostly on vanilla-style packs |
| Auto gen normal resolution | `NORMAL_GENERATION_RESOLUTION` | `128` | `16, 32, 64, 128, 256, 512, 1024`; minor performance effect |

#### Water Material Settings

| UI label | Setting | Default | Values / meaning |
|---|---|---:|---|
| Water noise | `WATER_NOISE` | On | Varies water brightness with noise |
| Water brightness | `WATER_BRIGHTNESS` | `1.00` | `0.00` to `1.00`, step `0.05`; lower is deeper color |
| Water normalmap | `WATER_NORMAL` | On | Water surface normals |
| Water normalmap blur size | `WATER_BLUR_SIZE` | `8.0` | `1, 2, 4, 8, 16, 32, 64`; smaller is more defined waves |
| Water normalmap depth size | `WATER_DEPTH_SIZE` | `0.5` | `0.125, 0.25, 0.5, 1.0, 2.0`; smaller is deeper |
| Water tile size | `WATER_TILE_SIZE` | `16` | `4, 8, 16, 24, 32` |
| Water absorption | `WATER_STYLIZE_ABSORPTION` | On | Depth-based stylized absorption |
| Water foam | `WATER_FOAM` | On | Foam at solid surfaces, including entities |
| Flat water albedo | `WATER_FLAT` | Off | Flat water albedo |

#### Lava Material Settings

| UI label | Setting | Default | Values / meaning |
|---|---|---:|---|
| Lava brightness | `LAVA_BRIGHTNESS` | `1.00` | `0.00` to `1.00`, step `0.05` |
| Lava noise | `LAVA_NOISE` | On | Lava brightness noise |
| Lava tile size | `LAVA_TILE_SIZE` | `16` | `4, 8, 16, 24, 32` |

#### Sculk Material Settings

| UI label | Setting | Default | Values / meaning |
|---|---|---:|---|
| Sculk brightness | `SCULK_BRIGHTNESS` | `1.00` | `0.00` to `1.00`, step `0.05` |
| Sculk noise | `SCULK_NOISE` | On | Sculk emission noise |
| Sculk tile size | `SCULK_TILE_SIZE` | `8` | `2, 4, 8, 16, 24` |

## Configuration

The Configuration screen holds the per-dimension settings and the block light page. The labels below are the `en_US.lang` labels. Option IDs, ranges, and defaults for every dimension are in [DIMENSION.md](DIMENSION.md).

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

Menu ranges: color channels `3` to `255`, step `3`; intensities `0.00` to `2.00`, step `0.05`. Other ranges are declared in each dimension's `world.glsl`.

### Block Light Page

| Exact UI label | Setting ID | Default | Values |
|---|---|---:|---|
| Block light red | `BLOCKLIGHT_R` | `255` | `3` to `255`, step `3` |
| Block light green | `BLOCKLIGHT_G` | `240` | `3` to `255`, step `3` |
| Block light blue | `BLOCKLIGHT_B` | `210` | `3` to `255`, step `3` |
| Block light intensity | `BLOCKLIGHT_I` | `1.00` | `0.00` to `2.00`, step `0.05` |

Dimension option ranges are declared in each `world.glsl`; see [DIMENSION.md](DIMENSION.md).

## Developers

This section documents source-side values that do not appear as player options. They are listed for implementation work and are intentionally hidden from the shader menu.

### Per-Dimension Settings

The former developer-only world flags (forced-off clouds, weather, and day cycle, sky ground, Aether, custom skylight, stars, and vanilla fog color) are now regular options on each dimension's Configuration screens. Option IDs, resolution, and defaults per dimension are in [DIMENSION.md](DIMENSION.md). Only `WORLD_ID` and `WORLD_PREFIX` remain source-level identifiers that don't appear in the menu.

The Dimensional Doors world files are credited to Kawwabi.

### Shadow Sampling Constants

`shaders/lib/lighting/shdSampleVar.glsl` defines the shadow controls and implementation constants.

| Setting | Default | Domain / status |
|---|---:|---|
| `shadowMapResolution` | `1024` | Menu setting: `512` to `8192`, step `512` |
| `shadowDistance` | `128.0` blocks | Menu setting: `32.0` to `1024.0`, step `32.0` |
| `sunPathRotation` | `30.0` degrees | Menu setting: `-60.0` to `60.0`, step `5.0` |
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
| `shaders/lib/settings.glsl` | Shared feature toggles, numeric defaults, and Physics Mod constants |
| `shaders/shaders.properties` | Menu registration, profiles, slider lists, render-target size, program enable rules, custom uniforms |
| `shaders/lang/en_US.lang` | Exact English names, descriptions, and enum labels shown to users |
| `shaders/lib/lighting/shdSampleVar.glsl` | Shadow-map settings and derived shadow values |
| `shaders/world-X/world.glsl` | Per-dimension options and defaults; see [DIMENSION.md](DIMENSION.md) |
| `shaders/lib/dimension/` | World resolver and the sky, light, fog, and star adapters |