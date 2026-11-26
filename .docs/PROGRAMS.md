# Shader Programs

**Scope**: Complete reference for all shader programs, classification, and rendering details  
**Related Docs**: [ARCHITECTURE.md](ARCHITECTURE.md) | [BUFFERS.md](BUFFERS.md) | [FEATURES.md](FEATURES.md)

---

## Table of Contents

1. [Program Classification](#program-classification)
2. [Shadow Programs](#shadow-programs)
3. [Gbuffer Programs](#gbuffer-programs)
4. [Deferred Programs](#deferred-programs)
5. [Composite Programs](#composite-programs)
6. [Final Program](#final-program)
7. [Compatibility and Support](#compatibility-and-support)
8. [Program File Organization](#program-file-organization)

---

## Program Classification

Super Duper Vanilla groups shader programs by the amount and type of shading work they perform:

### Classification Tiers

| Tier | Shading approach | Typical characteristics |
|------|------------------|------------------------|
| **Complex** | Full forward/PBR shading | Shadowing, material response, surface detail, and subsurface scattering |
| **Basic** | Reduced shading | A subset of the lighting and material work (for example, shadows without PBR) |
| **Simple** | Minimal shading | Unlit or lightly lit output that needs few additional effects |
| **Disabled** | No visible shading | Program is discarded or moved off screen by the source |

Distant Horizons and Voxy programs use a simplified LOD shading path (`complexShadingLOD.glsl`) with no shadow-map sampling. They are listed as Complex because they carry PBR material data, but their shading is cheaper than the vanilla complex programs.

### Provider / Loader Availability

This column identifies which loader or mod integration exposes a program; it does not imply that SDV currently supports every listed loader. The original project matrix is preserved in [LEGACY.md](LEGACY.md). SDV is Iris-only since 1.3.7, so OptiFine entries below are historical labels from that matrix.

| Program family | Provider / loader availability |
|---|---|
| `shadow`, `shadow_solid`, `shadow_cutout` | Iris; OptiFine (legacy entry) |
| `shadow_block`, `shadow_entities`, `shadow_water`, `shadow_lightning` | Iris |
| `physics_ocean_shadow`, `physics_ocean` | Physics Mod |
| `dh_terrain`, `dh_generic`, `dh_water` | Distant Horizons |
| `voxy_opaque`, `voxy_translucent` (with `voxy.json`) | Voxy |
| `gbuffers_armor_glint`, `gbuffers_basic`, `gbuffers_beaconbeam`, `gbuffers_damagedblock`, `gbuffers_line`, `gbuffers_skybasic`, `gbuffers_skytextured`, `gbuffers_terrain` | Iris; OptiFine (legacy entry) |
| `gbuffers_particles`, `gbuffers_lightning` | Iris |
| `gbuffers_entities`, `gbuffers_block`, `gbuffers_hand` | Iris; OptiFine (legacy entry) |
| `gbuffers_clouds`, `gbuffers_textured`, `gbuffers_spidereyes`, `gbuffers_water`, `gbuffers_weather` | Iris; OptiFine (legacy entry) |
| `deferred`, `composite` programs, `final` | Iris; OptiFine (legacy entry) |

For loader behavior and specifications, see [IrisShaders/docs](https://github.com/IrisShaders/docs) or the [OptiFine shader specification](https://github.com/sp614x/optifine/blob/master/OptiFineDoc/doc/shaders.txt#L447).

### Dimension-Specific Program Variants

Every program has a wrapper in each dimension folder, and each folder supplies its own `world.glsl` with that dimension's settings. The wrappers are otherwise identical to `world0`. Dimension assignment is defined in `dimension.properties`:

| Folder | Dimensions |
|---|---|
| `world0` | Overworld |
| `world-1` | The Nether and Undergarden |
| `world1` | The End |
| `world-2` | Dimensional Doors public and dungeon pockets |
| `world-3` | Dimensional Doors Limbo |
| `world-4` | Dimensional Doors personal pockets |
| `world999` | Wildcard: every dimension not listed above (`*`), such as modded dimensions |

Program enable conditions in `shaders.properties` are repeated per dimension folder. See [DIMENSION.md](DIMENSION.md) for how each folder's `world.glsl` is resolved and what it contains.

---

## Shadow Programs

### Purpose

Render scene geometry from the light source's perspective to generate the shadow depth map (`shadowtex0`), which forward-shaded gbuffers programs and the volumetric pass use for shadow calculations.

### Shadow Program Specifications

| Program | Input | Blend | Tier | Notes |
|---------|-------|-------|------|-------|
| `shadow` | Terrain and everything not matched below | Off | Complex | Primary shadow pass: terrain and water animation, world curvature, colored shadows, water caustics; removes the dragon death beam from the shadow map |
| `shadow_solid` | Solid blocks | Off | Basic | Terrain animation, world curvature, alpha test; writes black |
| `shadow_cutout` | Alpha-tested materials | Off | Basic | Same code as `shadow_solid` |
| `shadow_block` | Block entities | Off | Basic | World curvature, colored shadows |
| `shadow_entities` | Entities | Off | Basic | World curvature, colored shadows |
| `shadow_water` | Water surfaces | Off | Complex | Water animation, caustics, colored shadows |
| `shadow_lightning` | Lightning bolts | Off | Disabled | Always moved off screen and discarded |
| `physics_ocean_shadow` | Physics Mod ocean | Off | Complex | Ocean displacement, caustics, colored shadows (Physics Mod only) |

All shadow programs are moved off screen and discarded when `WORLD_LIGHT` is `0` or `SHADOW_MAPPING` is not defined. Alpha testing in shadow programs is done manually with `ALPHA_THRESHOLD` (`0.1`) instead of the pack's alpha-test properties.

### Execution Details

**Shadow Resolution Configuration**:
- The menu accepts `shadowMapResolution` values from 512 × 512 through 8192 × 8192 in steps of 512 (default 1024).
- Shadow-map pixel count scales with the square of the selected resolution.

**Shadow Distance**:
- `shadowDistance` (default 128 blocks, 32 to 1024 in steps of 32) controls how far shadows render.
- Increasing the distance reduces resolution per world-space unit, so the setting balances shadow quality against distance coverage.
- Entity shadows use half of the shadow distance (`entityShadowDistanceMul = 0.5`, Iris only).
- Shadows are warped with a distortion function (`shdDistort.glsl`) that gives nearby geometry more resolution.

**Shadow Color** (optional):
- `SHADOW_COLOR` is enabled by default in `settings.glsl`.
- With it enabled, fully opaque pixels write black (this prevents color leaking in filtered shadows), non-water translucent pixels such as stained glass write their albedo, and water writes its albedo modulated by caustics.
- With it disabled, shadow programs only alpha-test and write black.
- `shadowcolor0` is not cleared between frames.

---

## Gbuffer Programs

### Purpose

Render Minecraft geometry while populating G-buffer and scene targets. Most complex programs also perform forward shading, including shadow-map sampling. The target sets each program writes are listed in [BUFFERS.md](BUFFERS.md).

Alpha testing is disabled in `shaders.properties` for all gbuffers programs and handled in the shaders with `ALPHA_THRESHOLD`.

### Gbuffer Program Tiers & Classification

#### Complex Shading Programs (Full PBR)

Programs using the full material and lighting path where supported:

| Program | Input | Blend | PBR | Key features |
|---|---|---|---|---|
| `gbuffers_terrain` | Terrain mesh | Off | Full | TAA jitter, wave animation, lava and sculk noise, POM, curvature; Dimensional Doors fabric blocks bypass shading |
| `gbuffers_entities` | Entity meshes | Transparent | Full | Material shading, subsurface scattering, entity color tint, nametag alpha, curvature (no TAA jitter) |
| `gbuffers_hand` | Player hand | Transparent | Full | TAA jitter, parallax and material shading (no curvature) |
| `gbuffers_block` | Block entities | Transparent | Full | TAA jitter, material and emission data, End portal and Dimensional Doors portal, curvature |
| `gbuffers_water` | Water surface | Transparent | Full | TAA jitter, refraction-style depth effects, caustics, water noise, normals, absorption and foam, Nether portal edge, curvature |
| `physics_ocean` | Physics Mod ocean | Transparent | Full | Ocean displacement, foam, water absorption |
| `dh_terrain` | Distant Horizons terrain | Off | Simplified | Noise-varied albedo, lava, illuminated blocks, leaves subsurface, simplified LOD shading |
| `dh_water` | Distant Horizons water | Transparent | Simplified | Water normals, absorption and foam, discards where real geometry exists, simplified LOD shading |
| `voxy_opaque` | Voxy terrain | Off | Simplified | Material IDs from `customId`, lava, leaves subsurface, simplified LOD shading |
| `voxy_translucent` | Voxy water | Transparent | Simplified | Water normals, absorption and foam, discards where real geometry exists |

#### Basic Shading Programs (Simplified PBR)

These programs use reduced or specialized shading paths:

| Program | Input | Blend | Features |
|---|---|---|---|
| `gbuffers_basic` | Basic geometry | Off | Basic shading with shadow mapping, TAA jitter, curvature |
| `gbuffers_line` | Debug lines | Off | Vertex color output with line thickness expansion; GLSL 3.3 Core |
| `gbuffers_particles` | Particles | Transparent | Basic shading with shadow mapping, emissive particle detection |
| `gbuffers_textured` | Textured objects | Transparent | Unlit albedo scaled by `EMISSIVE_INTENSITY`, TAA jitter, curvature |
| `dh_generic` | Distant Horizons objects | Off | Unlit vertex color scaled by `EMISSIVE_INTENSITY` |

#### Simple/Minimal Programs

Programs with specialized or minimal material shading:

| Program | Input | Blend | Features |
|---|---|---|---|
| `gbuffers_damagedblock` | Block damage overlay | Default | Texture output only |
| `gbuffers_armor_glint` | Enchantment glint | Additive | Squared glint pattern, curvature |
| `gbuffers_beaconbeam` | Beacon beam | Default | Emissive beam color, TAA jitter, curvature |
| `gbuffers_spidereyes` | Spider eyes and other glowing eyes | Additive | Emissive color from texture luminance |
| `gbuffers_clouds` | Vanilla clouds | Off | Only active when `CLOUD_TYPE` is `0`; gradient shading |
| `gbuffers_weather` | Rain and snow | Default | Sky and lightmap diffuse, wave animation; discarded when `WORLD_WEATHER` is `0` |
| `gbuffers_lightning` | Lightning | Additive | Lightning bolt color (`entityId` `10129`) and emissive color |
| `gbuffers_skytextured` | Skybox, sun and moon | Additive | Vanilla sun and moon only when `SUN_MOON_TYPE` is `2`; skybox brightness |
| `gbuffers_skybasic` | Basic sky | Off | Disabled (moved off screen, discards) |

### Gbuffer Program Groups

The programs are grouped by when they run, following the original project categories:

```
1. BEFORE DEFERRED (solid, written with mask 0 or no material mask)
   ├─ gbuffers_terrain
   ├─ dh_terrain
   ├─ dh_generic
   ├─ voxy_opaque
   ├─ gbuffers_basic
   ├─ gbuffers_line (GLSL 3.3 Core)
   ├─ gbuffers_skytextured
   ├─ gbuffers_skybasic (disabled)
   ├─ gbuffers_damagedblock
   ├─ gbuffers_armor_glint
   └─ gbuffers_beaconbeam

2. MIXED (forward-shaded, written with mask 0.5 and finished in composite)
   ├─ gbuffers_entities
   ├─ gbuffers_block
   ├─ gbuffers_hand
   └─ gbuffers_particles (particles.ordering = after)

3. BEFORE COMPOSITE (translucent and special)
   ├─ gbuffers_water
   ├─ dh_water
   ├─ voxy_translucent
   ├─ physics_ocean
   ├─ gbuffers_textured
   ├─ gbuffers_clouds
   ├─ gbuffers_weather
   ├─ gbuffers_lightning
   └─ gbuffers_spidereyes
```

Buffer ownership and producer/consumer lanes are documented in [BUFFERS.md](BUFFERS.md). The exact ordering of the mixed group relative to `deferred` is controlled by Iris; the pack sets `separateEntityDraws = true` and `particles.ordering = after` in `shaders.properties`.

---

## Deferred Programs

### Purpose

Deferred programs read geometry and material data and produce screen-space results. Direct lighting is already computed forward in the gbuffers programs, so the deferred stage handles ambient occlusion, reflections, sky, outlines, and fog.

### Deferred Program Specifications

| Program | Main output | Role |
|---|---|---|
| `deferred` | `colortex2` | Writes SSAO into the alpha channel when `SSAO` is enabled; otherwise copies albedo |
| `deferred1` | `colortex4` | Sky render, SSR and SSGI reflections, outlines, SSAO application, fog |

### Execution Details

`deferred` skips the sky, the player hand (depth `<= 0.56`), and pixels with no normal, then runs a four-sample SSAO. Its default alpha is `0.25`.

`deferred1` first renders the sky for pixels whose depth is `1` (using Distant Horizons or Voxy depth when those mods are active). For other pixels it reads normals, albedo, and material data, then:

1. applies SSR, SSGI, and sky reflections through `complexShadingDeferred`;
2. applies outlines when `OUTLINES` is not `0`;
3. multiplies by a four-tap box blur of the SSAO alpha;
4. applies ground fog, border fog, and darkness fog.

---

## Composite Programs

### Purpose

Ordered post-processing programs. A program may read a buffer written several passes earlier; consult the source outputs and configured enable conditions rather than assuming each pass consumes the previous pass's output.

There are fifteen composite programs: `composite` (slot 0) and `composite1` to `composite14`. Enable conditions are defined in `shaders.properties`, repeated per dimension folder.

| Program | Enabled when |
|---|---|
| `composite`, `composite1`, `composite3`, `composite13`, `composite14` | Always |
| `composite2` | `VOLUMETRIC_LIGHTING` and `SHADOW_MAPPING` |
| `composite4` | `ANTI_ALIASING >= 2`, or `PREVIOUS_FRAME` with `SSR` or `SSGI` |
| `composite5` | `ANTI_ALIASING` is `1` or `3` |
| `composite6` | `MOTION_BLUR` |
| `composite7` | `DOF` |
| `composite8`, `composite9`, `composite10` | `BLOOM` |
| `composite11`, `composite12` | `LENS_FLARE` or `BLOOM` |

`composite13` is always scheduled but only does work when `AUTO_EXPOSURE` is enabled. `composite1` and `composite3` return early when `VOLUMETRIC_LIGHTING_STRENGTH` is `0` or the player is in lava.

When `VOLUMETRIC_LIGHTING` or `SHADOW_MAPPING` is off, `composite1` writes a cheap height-faded value instead of a shadow-map ray march, and `composite3` uses a fog-based light color. Set the strength to `0` to remove volumetrics fully.

### Composite Program Data Flow

| Stage | Main targets read | Main target written | Role |
|---|---|---|---|
| **Composite0** (`composite`) | `colortex0` (cloud map), `colortex1`-`colortex5`, depth | `colortex4` | Reflections and fog for forward-shaded geometry; voxel clouds |
| **Composite1** | Depth, shadow maps | Half-resolution `colortex0` | Volumetric ray marching (8 steps) |
| **Composite2** | `colortex0`, `colortex6`, depth | `colortex0`, `colortex6` | Temporal accumulation with neighborhood clamping |
| **Composite3** | `colortex0`, `colortex4`, depth | `colortex4` | Upsample volumetrics and apply them with fog density |
| **Composite4** | `colortex4`, `colortex5`, depth | `colortex4`, `colortex5` | TAA and previous-frame color |
| **Composite5** | `colortex4` | `colortex4` | FXAA on the HDR scene for modes 1 and 3 |
| **Composite6** | `colortex4`, depth | `colortex4` | Motion blur |
| **Composite7** | `colortex4` mips, `depthtex1` | `colortex4` | Depth of field |
| **Composite8** | `colortex4` mips | Half-resolution `colortex0` | Bloom tile downsample |
| **Composite9** | `colortex0` | `colortex0` | Bloom horizontal blur |
| **Composite10** | `colortex0` | `colortex0` | Bloom vertical blur |
| **Composite11** | `colortex0` | `colortex0` | Bloom upsample and lens flare |
| **Composite12** | `colortex4`, `colortex0` | `colortex4` | Apply bloom |
| **Composite13** | `colortex4` (LOD 8), `colortex7` | `colortex7` | Auto exposure |
| **Composite14** | `colortex4`, `colortex7` | `colortex3` | Exposure, tint, tonemapping, gamma, contrast, saturation, vignette, dithering |

### Composite Execution Details

**Sequential Dependency Chain**:
```
Composite0 applies reflections and fog to forward-shaded geometry, then draws voxel clouds
Composite1 ray-marches volumetrics into half-resolution colortex0
Composite2 accumulates volumetrics over time using colortex6 history
Composite3 upsamples the volumetric result and adds it to colortex4
Composite4 performs TAA when enabled and writes previous-frame color to colortex5
Composite5 performs FXAA when selected
Composite6-7 apply motion blur and depth of field
Composite8-11 build bloom through colortex0 and add lens flare
Composite12 applies bloom to colortex4
Composite13 updates auto exposure in colortex7
Composite14 tonemaps and writes display-oriented output to colortex3
```

Passes execute in order, but adjacent programs can read and write different targets; see the data-flow table above.

**Key Stages Explained**:

- **Composite0**: For pixels with a shading mask between `0` and `1`, applies SSR, SSGI, and sky reflections and fog. Then renders voxel clouds when `CLOUD_TYPE != 0`, clouds are not force-disabled, and the world has light.
- **Composite1-3**: Ray-march volumetrics at half resolution, accumulate temporal history (blend of `0.1` current and `0.9` history), then upsample and add them to the HDR scene.
- **Composite4**: TAA keeps neighborhood-clamped history in `colortex5`. `ANTI_ALIASING == 3` (Lite TAA + FXAA) runs this pass without projection jitter.
- **Composite5**: FXAA, when selected by the anti-aliasing setting.
- **Composite8-11**: Bloom uses five tiles from `colortex4` mip levels 1 to 5, a 9-tap Gaussian blur done with five fetches per axis, then a tent-filter upsample. `composite11` also adds the lens flare.
- **Composite12**: Blends bloom into the scene by luminance and `BLOOM_STRENGTH`.
- **Composite13**: Samples the center of the scene at LOD 8, smooths it by `AUTO_EXPOSURE_SPEED * frameTime`, and stores it in `colortex7`.
- **Composite14**: Applies auto exposure (clamped by `MINIMUM_EXPOSURE`), vignette, tint and `EXPOSURE`, a Reinhard-Jodie extended tonemap, gamma correction, contrast, saturation, and dithering.

---

## Final Program

### Purpose

Final full-screen filtering and output to screen. `final` also declares the buffer formats and clear flags for the whole pack (see [BUFFERS.md](BUFFERS.md)).

### Final Program Specifications

| Aspect | Value |
|--------|-------|
| Input Buffer | Final color produced in `colortex3` by `composite14` |
| Output | Screen framebuffer |
| Processing | Retro filter, chromatic aberration, optional sharpening (only when anti-aliasing is not off) |

---

## Compatibility and Support

Maintained builds target Iris 1.6.10 or later on Minecraft 1.18.2 or later. The README lists support on Windows and Linux with Intel, AMD, or NVIDIA GPUs, and on Apple M1. Minecraft 1.17.1 and earlier are listed as unsupported.

| Historical loader entry | Minecraft version | Windows / Linux (Intel, AMD, NVIDIA) | Apple M1 |
|---|---|---|---|
| OptiFine | 1.17.1 and later | Partial support | Partial support |
| OptiFine | 1.14.2 and later | Partial support | Not supported |
| OptiFine | 1.13.2 and earlier | Not supported | Not supported |

OptiFine maintenance ended with SDV 1.3.7; these entries are historical and are not a current support commitment. Older AMD graphics drivers may show visual issues (the pack includes a workaround in `getDepth` for AMD depth values). Pojav Launcher use is possible but unofficial, and results vary by device. For mod-compatibility requests, open a repository issue with a link to the mod; code contributions should follow [CONTRIBUTION.md](../CONTRIBUTION.md).

---

## Program File Organization

### Source Directory

```
shaders/
├── block.properties            # Block IDs
├── dimension.properties        # Dimension to world folder mapping
├── entity.properties           # Entity IDs
├── shaders.properties          # Menu, profiles, program enables, buffer sizes, uniforms
├── lang/                       # Language files (en_US.lang is the main file)
├── lib/                        # Shared GLSL libraries
│   ├── antialiasing/           # FXAA and TAA
│   ├── atmospherics/           # Sky and fog
│   ├── dimension/              # World resolver and sky, light, fog, and star adapters
│   ├── lighting/               # Shadows, GGX, SSAO, shading
│   ├── modded/                 # Mod shared code (Distant Horizons + Voxy, Physics Mod)
│   ├── PBR/                    # Integrated PBR, LabPBR, environment PBR
│   ├── post/                   # Tonemap, bloom helpers, lens flare, outlines, motion blur
│   ├── rayTracing/             # Ray tracer, volumetric light, clouds
│   ├── surface/                # Water and lava noise
│   ├── utility/                # Common functions, projection, noise
│   ├── vertex/                 # Terrain, water, and weather animation
│   └── settings.glsl           # Shared settings
├── main/                       # Shared program implementations (.glsl)
│   ├── gbuffers/               # Geometry program implementations
│   ├── modded/                 # Distant Horizons, Voxy, and Physics Mod programs
│   ├── shadow/                 # Shadow program implementations
│   ├── composite.glsl          # Composite 0
│   ├── composite1.glsl         # ... through composite14.glsl
│   ├── deferred.glsl
│   ├── deferred1.glsl
│   └── final.glsl              # Final output program, buffer formats
├── textures/                   # Noise and cloud textures
└── world0/ world-1/ world1/ world-2/ world-3/ world-4/ world999/
    ├── *.fsh / *.vsh           # Loader-facing program wrappers
    └── world.glsl              # Per-dimension settings
```

### Dimension-Specific Overrides

Each `world-X/` folder contains the same program wrappers, differing only through that folder's `world.glsl`. Every `world.glsl` exposes the same option set, so per-dimension differences are values, not different options:
- Feature flags: skybox, clouds, weather, day cycle, real skylight, directional light, stars, aether, sky ground, and vanilla fog color
- Skylight amount, celestial body and size, and vanilla fog mode and strength
- Star intensity, light and sky colors, and fog densities for constant, day, night, and twilight

See [DIMENSION.md](DIMENSION.md) for the option reference and [SETTINGS.md](SETTINGS.md) for the menu screens.

---

## References

- **[ARCHITECTURE.md](ARCHITECTURE.md)** - Pipeline overview
- **[BUFFERS.md](BUFFERS.md)** - Buffer lanes and data packing
- **[FEATURES.md](FEATURES.md)** - Feature implementation details
- **[LEGACY.md](LEGACY.md)** - Original program classifications