# Settings Wiki

A reference for the settings available in Super Duper Vanilla (SDV), using the exact English names from `shaders/lang/en_US.lang` and the identifiers/defaults from the shader sources.

`shaders/lib/settings.glsl` defines shared settings and source defaults. `shaders/shaders.properties` controls the menu, profile inheritance, sliders, and program conditions. Profiles can override the source defaults. Per-world values are defined in `shaders/worldX/world.glsl`.

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

## Profiles

The profile names displayed by the menu are **Potato**, **Low**, **Medium (Default)**, **High**, and **Ultra**. IDs and assignments come from `shaders/shaders.properties`. Each profile inherits from the preceding profile.

| UI label | ID | Added or changed assignments |
|---|---|---|
| Potato | `POTATO` | Sets `CLOUD_TYPE:0`, `ANTI_ALIASING:1`; disables volumetrics, shadows, shadow color/filter, SSAO, rough reflections, previous-frame data, SSR, bloom, and sharpening |
| Low | `LOW` | From Potato: `CLOUD_TYPE:1`, enables shadows/SSR/bloom, `RAYTRACER_STEPS:8`, `RAYTRACER_BISTEPS:2`, `shadowMapResolution:512`, `UNDERWATER_CAUSTICS:0` |
| Medium (Default) | `MEDIUM` | From Low: enables volumetrics, shadow color/filter, rough reflections, SSAO, previous-frame data; sets AA to TAA, ray steps `16`, refinement `4`, shadow resolution `1024`, caustics `1` |
| High | `HIGH` | From Medium: ray steps `32`, shadow resolution `2048` |
| Ultra | `ULTRA` | From High: ray steps `64`, sharpening enabled, shadow resolution `4096`, caustics `2` |

These are profile assignments, not a second set of base defaults. The complete definitions remain in `shaders/shaders.properties`.

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
| Retro filter | `RETRO_FILTER` | Off | Enables retro presentation filter |
| Anti aliasing | `ANTI_ALIASING` | `2` | `0` OFF, `1` FXAA, `2` TAA, `3` Lite TAA + FXAA |
| Sharpen filter | `SHARPEN_FILTER` | Off | Enables image sharpening; the source describes this for use with AA |

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
| Auto exposure | `AUTO_EXPOSURE` | Off | Enables real-time auto exposure |
| Auto exposure speed | `AUTO_EXPOSURE_SPEED` | `1.00` | `0.00` to `2.00`, step `0.05`; higher values adapt faster |
| Exposure | `EXPOSURE` | `1.00` | `0.00` to `2.00`, step `0.05` |
| Min exposure | `MINIMUM_EXPOSURE` | `0.10` | `0.10` to `0.90`, step `0.10` |
| Red tint | `TINT_R` | `255` | `3` to `255`, step `3` |
| Green tint | `TINT_G` | `255` | `3` to `255`, step `3` |
| Blue tint | `TINT_B` | `255` | `3` to `255`, step `3` |

## Lighting

| UI label | Setting | Default | Values / meaning |
|---|---|---:|---|
| Shadowmapping | `SHADOW_MAPPING` | On | Dynamic shadow mapping; disabled mode uses lightmap-based fake shadows |
| Shadowmap color | `SHADOW_COLOR` | On | Colored data from transparent shadow casters |
| Shadowmap filter | `SHADOW_FILTER` | On | Noise-based soft shadow filtering |
| Entity shadows | `ENTITY_SHADOWS` | On | Enables entity shadows |
| Block entity shadows | `BLOCK_ENTITY_SHADOWS` | On | Enables block-entity shadows |
| Underwater caustics | `UNDERWATER_CAUSTICS` | `1` | `0` OFF, `1` Underwater, `2` Full; requires shadow color |
| SSAO | `SSAO` | On | Screen-space ambient occlusion |
| Ambient lighting | `AMBIENT_LIGHTING` | `0.05` | `0.00` to `0.50`, step `0.01` |

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
| SSGI | `SSGI` | Off | Experimental screen-space global illumination |
| SSR | `SSR` | On | Screen-space reflections |
| Raytracer steps | `RAYTRACER_STEPS` | `16` | `2, 4, 8, 16, 32, 64, 128` |
| Raytracer refinement steps | `RAYTRACER_BISTEPS` | `4` | `0, 2, 4, 6, 8` |
| Rough reflections | `ROUGH_REFLECTIONS` | On | Roughness-dependent reflections |
| Previous frame buffer | `PREVIOUS_FRAME` | On | Previous-frame color for temporal reflection/GI accumulation |

## Atmospherics

| UI label | Setting | Default | Values / meaning |
|---|---|---:|---|
| Sun/moon type | `SUN_MOON_TYPE` | `0` | `0` Squircle, `1` Round, `2` Vanilla |
| Sun/moon intensity | `SUN_MOON_INTENSITY` | `4` | `0` through `8` |
| Volumetric lighting | `VOLUMETRIC_LIGHTING` | On | Enables volumetric lighting |
| Volumetric lighting strength | `VOLUMETRIC_LIGHTING_STRENGTH` | `0.50` | `0.00` to `1.00`, step `0.05`; zero disables its contribution |
| Border fog | `BORDER_FOG` | On | Covers visible world edges with fog |
| Ground fog strength | `GROUND_FOG_STRENGTH` | `0.50` | `0.00` to `1.00`, step `0.05` |
| Skybox brightness | `SKYBOX_BRIGHTNESS` | `1.00` | `0.00` to `2.00`, step `0.05` |

### Cloud Settings

| UI label | Setting | Default | Values / meaning |
|---|---|---:|---|
| Cloud type | `CLOUD_TYPE` | `1` | `0` Vanilla, `1` Voxel |
| Double layered clouds | `DOUBLE_LAYERED_CLOUDS` | On | Adds a second cloud layer |
| Dynamic clouds | `DYNAMIC_CLOUDS` | On | Weather-responsive cloud behavior |
| Fade speed | `FADE_SPEED` | `0.10` | `0.00` to `4.00`, step `0.05` |
| 2nd cloud height | `SECOND_CLOUD_HEIGHT` | `128.0` | `0.0` to `256.0`, step `4.0` |
| Cloud thickness | `CLOUD_THICKNESS` | `8.0` | `4.0, 6.0, 8.0, 10.0, 12.0` |

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
| PBR mode | `PBR_MODE` | `1` | `0` OFF, `1` Integrated PBR, `2` Lab PBR 1.3 |
| Specular highlights | `SPECULAR_HIGHLIGHTS` | On | Approximate sun reflections |
| Enviro PBR materials | `ENVIRONMENT_PBR` | On | Environment-dependent material response |
| Subsurface scattering | `SUBSURFACE_SCATTERING` | On | Scattering on thin/organic materials |
| Emissive intensity | `EMISSIVE_INTENSITY` | `8` | `2, 4, 8, 16, 32`; requires PBR; does not affect lightmaps |
| Normal strength | `NORMAL_STRENGTH` | `1.00` | `0.00` to `1.00`, step `0.05`; applies to resource-pack normals when applicable |
| Slope normals | `SLOPE_NORMALS` | Off | Slope-derived normals |
| Directional lightmaps | `DIRECTIONAL_LIGHTMAPS` | Off | Requires generated or PBR normals |
| Directional lightmaps strength | `DIRECTIONAL_LIGHTMAP_STRENGTH` | `1.00` | `0.00` to `1.00`, step `0.05` |
| Auto gen normals | `NORMAL_GENERATION` | Off | Generates normals; disabled with LabPBR |
| Auto gen normal resolution | `NORMAL_GENERATION_RESOLUTION` | `128` | `16, 32, 64, 128, 256, 512, 1024` |
| Parallax occlusion | `PARALLAX_OCCLUSION` | Off | Requires LabPBR and a LabPBR resource pack |
| Parallax depth | `PARALLAX_DEPTH` | `0.25` | `0.00` to `0.50`, step `0.05` |
| Parallax steps | `PARALLAX_STEPS` | `128` | `16, 32, 64, 128, 256, 512` |
| Parallax shadows | `PARALLAX_SHADOW` | On | Self-shadowing for parallax surfaces |
| Parallax shadow steps | `PARALLAX_SHADOW_STEPS` | `32` | `16, 32, 64, 128, 256, 512` |

### iPBR Material Subpages

#### Water Material Settings

| UI label | Setting | Default | Values / meaning |
|---|---|---:|---|
| Water noise | `WATER_NOISE` | On | Water surface noise/distortion |
| Water brightness | `WATER_BRIGHTNESS` | `1.00` | `0.00` to `1.00`, step `0.05` |
| Water normalmap | `WATER_NORMAL` | On | Water surface normals |
| Water normalmap blur size | `WATER_BLUR_SIZE` | `8.0` | `1, 2, 4, 8, 16, 32, 64` |
| Water normalmap depth size | `WATER_DEPTH_SIZE` | `0.5` | `0.125, 0.25, 0.5, 1.0, 2.0` |
| Water tile size | `WATER_TILE_SIZE` | `16` | `4, 8, 16, 24, 32` |
| Water absorption | `WATER_STYLIZE_ABSORPTION` | On | Depth-based stylized absorption |
| Water foam | `WATER_FOAM` | On | Foam at solid surfaces |
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

The Configuration screen contains separate Overworld, Nether, End, and Block light pages. The labels below are the `en_US.lang` labels; each world's values are defined in its own `world.glsl`.

### Overworld Pages

| Page | Exact UI label | Setting ID |
|---|---|---|
| Day settings | Light red | `LIGHT0_DR` |
| Day settings | Light green | `LIGHT0_DG` |
| Day settings | Light blue | `LIGHT0_DB` |
| Day settings | Light intensity | `LIGHT0_DI` |
| Day settings | Sky red | `SKY0_DR` |
| Day settings | Sky green | `SKY0_DG` |
| Day settings | Sky blue | `SKY0_DB` |
| Day settings | Sky intensity | `SKY0_DI` |
| Night settings | Light red | `LIGHT0_NR` |
| Night settings | Light green | `LIGHT0_NG` |
| Night settings | Light blue | `LIGHT0_NB` |
| Night settings | Light intensity | `LIGHT0_NI` |
| Night settings | Sky red | `SKY0_NR` |
| Night settings | Sky green | `SKY0_NG` |
| Night settings | Sky blue | `SKY0_NB` |
| Night settings | Sky intensity | `SKY0_NI` |
| Twilight settings | Light red | `LIGHT0_TR` |
| Twilight settings | Light green | `LIGHT0_TG` |
| Twilight settings | Light blue | `LIGHT0_TB` |
| Twilight settings | Light intensity | `LIGHT0_TI` |
| Twilight settings | Sky red | `SKY0_TR` |
| Twilight settings | Sky green | `SKY0_TG` |
| Twilight settings | Sky blue | `SKY0_TB` |
| Twilight settings | Sky intensity | `SKY0_TI` |
| Fog settings | Vertical density day | `FOG0_VERTICAL_DENSITY_D` |
| Fog settings | Vertical density night | `FOG0_VERTICAL_DENSITY_N` |
| Fog settings | Vertical density twilight | `FOG0_VERTICAL_DENSITY_T` |
| Fog settings | Total density | `FOG0_TOTAL_DENSITY` |

### Nether Page

| Exact UI label | Setting ID |
|---|---|
| Vertical density | `FOGn1_VERTICAL_DENSITY` |
| Total density | `FOGn1_TOTAL_DENSITY` |
| Sky intensity | `WORLDn1_VANILLA_FOGCOLI` |

### End Page

| Exact UI label | Setting ID |
|---|---|
| Light red | `LIGHT1_CR` |
| Light green | `LIGHT1_CG` |
| Light blue | `LIGHT1_CB` |
| Light intensity | `LIGHT1_CI` |
| Sky red | `SKY1_CR` |
| Sky green | `SKY1_CG` |
| Sky blue | `SKY1_CB` |
| Sky intensity | `SKY1_CI` |
| Vertical density | `FOG1_VERTICAL_DENSITY` |
| Total density | `FOG1_TOTAL_DENSITY` |

### Block Light Page

| Exact UI label | Setting ID | Default | Values |
|---|---|---:|---|
| Block light red | `BLOCKLIGHT_R` | `255` | `3` to `255`, step `3` |
| Block light green | `BLOCKLIGHT_G` | `240` | `3` to `255`, step `3` |
| Block light blue | `BLOCKLIGHT_B` | `210` | `3` to `255`, step `3` |
| Block light intensity | `BLOCKLIGHT_I` | `1.00` | `0.00` to `2.00`, step `0.05` |

RGB channels in light/sky pages use `3` to `255`, step `3`; their intensity settings use `0.00` to `2.00`, step `0.05`. World fog densities use the `0.005` to `0.500` domain declared in world files. The `blockLightColor` vector is derived from block-light RGB and intensity; it is not another menu option.

## Developers

This section documents source-side values that do not appear as player options. They are listed for implementation work and are intentionally hidden from the shader menu.

### Hidden Per-World Settings

These settings are set in `shaders/world-X/world.glsl`, not through `screen.*` options:

| Setting | Meaning |
|---|---|
| `WORLD_ID` | Dimension identifier |
| `WORLD_LIGHT` | Enables the shader sun/moon lighting path |
| `WORLD_SUN_MOON` | Per-world light mode: `0` off, `1` standard sun/moon, `2` black-hole path |
| `WORLD_SUN_MOON_SIZE` | Angular size for that world's light source |
| `FORCE_DISABLE_CLOUDS` | Forces cloud handling off in a dimension |
| `FORCE_DISABLE_WEATHER` | Forces weather handling off in a dimension |
| `FORCE_DISABLE_DAY_CYCLE` | Forces day-cycle handling off in a dimension |
| `WORLD_SKY_GROUND` | Enables the sky-ground path |
| `WORLD_AETHER` | Enables Aether particle handling |
| `WORLD_CUSTOM_SKYLIGHT` | Supplies a custom skylight amount |
| `WORLD_STARS` | Defines the dimension's star contribution |
| `WORLD_VANILLA_FOG_COLOR` | Selects vanilla fog color handling |
| `WORLD0_VANILLA_FOGCOLI`, `WORLD1_VANILLA_FOGCOLI` | Optional per-world vanilla fog-color intensity; not registered on the menu |

`WORLDn1_VANILLA_FOGCOLI` is the exception: it is registered as the Nether page's **Sky intensity** setting when defined. The Configuration page exposes selected world color and fog values, but the flags above remain developer-controlled.

Built-in world source defaults include:

| World | Selected defaults |
|---|---|
| Overworld (`world0`) | `WORLD_ID=0`, `WORLD_LIGHT`, `WORLD_SUN_MOON=1`, size `0.125`; day/night/twilight lighting and sky colors plus fog densities are declared in this file |
| Nether (`world-1`) | `WORLD_ID=-1`, no `WORLD_LIGHT`, `WORLD_SUN_MOON=0`; clouds/weather/day cycle forced off; custom skylight `1.00`; vertical fog `0.010`, total fog `0.020` |
| End (`world1`) | `WORLD_ID=1`, `WORLD_LIGHT`, `WORLD_SUN_MOON=2`, size `0.25`; clouds/weather/day cycle forced off; custom skylight `1.00`; Aether and sky-ground enabled; stars `16.0`; vertical fog `0.025`, total fog `0.005` |

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

The following are computed from settings rather than independently adjustable controls: `blockLightColor`, `cloudDepthInverse`, `cloudCenterDepth`, `cloudHeight`, `sunMoonIntensitySqrd`, `skyBoxIntensitySqrd`, `worldCurvatureInv`, and `waterTileSizeInv`.

### Source Map

| File | Settings responsibility |
|---|---|
| `shaders/lib/settings.glsl` | Shared feature toggles, numeric defaults, and Physics Mod constants |
| `shaders/shaders.properties` | Menu registration, profiles, slider lists, render-target size, program enable rules |
| `shaders/lang/en_US.lang` | Exact English names, descriptions, and enum labels shown to users |
| `shaders/lib/lighting/shdSampleVar.glsl` | Shadow-map settings and derived shadow values |
| `shaders/world-X/world.glsl` | Hidden world flags and per-world lighting/fog defaults |
