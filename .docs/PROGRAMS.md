# Shader Programs

**Scope**: Complete reference for all shader programs, classification, and rendering details  
**Related Docs**: [ARCHITECTURE.md](ARCHITECTURE.md) | [FEATURES.md](FEATURES.md)

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
| **Complex** | Full forward/PBR shading | May include shadowing, material response, surface detail, and subsurface scattering |
| **Basic** | Reduced shading | Uses a subset of the lighting/material work needed by the program |
| **Simple** | Minimal shading | Handles programs whose output requires few additional effects |
| **Disabled** | No visible shading | Program is discarded or disabled by configuration |

### Provider / Loader Availability

This column identifies which loader or mod integration exposes a program; it does not imply that SDV currently supports every listed loader. The original project matrix is preserved in [LEGACY.md](LEGACY.md). SDV is Iris-only since 1.3.7, so OptiFine entries below are historical labels from that matrix.

| Program family | Provider / loader availability |
|---|---|
| `shadow`, `shadow_solid`, `shadow_cutout` | Iris; OptiFine (legacy entry) |
| `shadow_block`, `shadow_entities`, `shadow_water`, `shadow_lightning` | Iris |
| `physics_ocean_shadow`, `physics_ocean` | Physics Mod |
| `dh_terrain`, `dh_generic`, `dh_water` | Distant Horizons |
| `gbuffers_armor_glint`, `gbuffers_basic`, `gbuffers_beaconbeam`, `gbuffers_damagedblock`, `gbuffers_line`, `gbuffers_skybasic`, `gbuffers_skytextured`, `gbuffers_terrain` | Iris; OptiFine (legacy entry) |
| `gbuffers_particles`, `gbuffers_lightning` | Iris |
| `gbuffers_entities`, `gbuffers_block`, `gbuffers_hand` | Iris; OptiFine (legacy entry) |
| `gbuffers_clouds`, `gbuffers_textured`, `gbuffers_spidereyes`, `gbuffers_water`, `gbuffers_weather` | Iris; OptiFine (legacy entry) |
| `deferred`, `composite` programs | Iris; OptiFine (legacy entry) |

For loader behavior and specifications, see [IrisShaders/docs](https://github.com/IrisShaders/docs) or the [OptiFine shader specification](https://github.com/sp614x/optifine/blob/master/OptiFineDoc/doc/shaders.txt#L447).
For loader-specific behavior and specifications, see [IrisShaders/docs](https://github.com/IrisShaders/docs) or the [OptiFine shader specification](https://github.com/sp614x/optifine/blob/master/OptiFineDoc/doc/shaders.txt#L447).

### Dimension-Specific Program Variants

Dimension macros are configured per world. See [SETTINGS.md](SETTINGS.md) for their definitions; this document owns program behavior and ordering.

## Compatibility and Support

Maintained builds target Iris 1.6.10 or later on Minecraft 1.18.2 or later. The README lists support on Windows and Linux with Intel, AMD, or NVIDIA GPUs, and on Apple M1. Minecraft 1.17.1 and earlier are listed as unsupported.

| Historical loader entry | Minecraft version | Windows / Linux (Intel, AMD, NVIDIA) | Apple M1 |
|---|---|---|---|
| OptiFine | 1.17.1 and later | Partial support | Partial support |
| OptiFine | 1.14.2 and later | Partial support | Not supported |
| OptiFine | 1.13.2 and earlier | Not supported | Not supported |

OptiFine maintenance ended with SDV 1.3.7; these entries are historical and are not a current support commitment. Older AMD graphics drivers may show visual issues. Pojav Launcher use is possible but unofficial, and results vary by device. For mod-compatibility requests, open a repository issue with a link to the mod; code contributions should follow [CONTRIBUTION.md](../CONTRIBUTION.md).

---

## Shadow Programs

### Purpose

Render scene geometry from the light source's perspective to generate the shadow depth map (`shadowtex0`), which subsequent stages use for shadow calculations.

### Shadow Program Specifications

| Program | Input | Blend | Tier | Notes |
|---------|-------|-------|------|-------|
| `shadow` | Opaque blocks | Solid | Complex | Primary shadow pass (default) |
| `shadow_solid` | Solid blocks | Solid | Complex | Solid geometry shadow variant |
| `shadow_cutout` | Alpha-tested materials | Solid | Complex | Cutout/masked leaves, glass |
| `shadow_block` | Block entity models | Solid | Basic | Block-specific shadow rendering |
| `shadow_entities` | Living entities/mobs | Solid | Complex | Optional entity shadows |
| `shadow_water` | Water surfaces | Solid | Complex | Water-specific shadow pass |
| `shadow_lightning` | Lightning bolts | Solid | Complex | **DISABLED** - `discard;` always |
| `physics_ocean_shadow` | Physics ocean mods | Solid | Complex | Physics mod support (if installed) |

### Execution Details

**Shadow Resolution Configuration**:
- The menu accepts `shadowMapResolution` values from 512 × 512 through 8192 × 8192 in steps of 512.
- Shadow-map pixel count scales with the square of the selected resolution.

**Shadow Distance**:
- Affects how far shadows render
- Controls how far shadows render.
- Increasing the distance reduces resolution per world-space unit.
- The setting balances shadow quality against distance coverage.

**Shadow Color** (Optional):
- Stores color information for transparent shadow casters.
- `SHADOW_COLOR` is enabled by default in `settings.glsl`.

---

## Gbuffer Programs

### Purpose

Render Minecraft geometry while populating G-buffer and scene targets. Some programs also perform forward shading. The configured sequence is summarized below.

### Gbuffer Program Tiers & Classification
### G-buffer Program Classification

#### Complex Shading Programs (Full PBR)

Programs using the full material and lighting path where supported:

| Program | Input | Blend | PBR | Key features |
|---|---|---|---|---|
| `gbuffers_terrain` | Terrain mesh | Solid | Full | TAA jitter, wave animation, POM, material shading |
| `gbuffers_entities` | Entity meshes | Transparent | Full | Material shading and subsurface scattering |
| `gbuffers_hand` | Player hand | Transparent | Full | Parallax and material shading |
| `gbuffers_block` | Block geometry | Transparent | Full | Material and emission data |
| `gbuffers_water` | Water surface | Transparent | Full | Refraction, caustics, wave animation |
| `dh_terrain` | Distant Horizons terrain | Solid | Simplified | Animated distant terrain shading |

#### Basic Shading Programs (Simplified PBR)

These programs use reduced or specialized shading paths:

| Program | Input | Blend | Features |
|---|---|---|---|
| `gbuffers_basic` | Basic geometry | Solid | Basic lighting |
| `gbuffers_line` | Debug lines | Solid | Line color output; GLSL 3.3 Core |
| `gbuffers_textured` | Textured objects | Transparent | Texture and basic lighting |
| `gbuffers_particles` | Particles | Transparent | Vertex-color shading |
| `dh_generic` | Distant Horizons objects | Solid | Generic distant-object rendering |
| `gbuffers_damagedblock` | Block damage overlay | Solid | Damage-stage rendering |

#### Simple/Minimal Programs

Programs with specialized or minimal material shading:

| Program | Input | Blend | Features |
|---|---|---|---|
| `gbuffers_armor_glint` | Enchantment glint | Additive | Glint pattern |
| `gbuffers_beaconbeam` | Beacon beam | Additive | Beam color |
| `gbuffers_spidereyes` | Spider eyes | Additive | Emissive color |
| `gbuffers_clouds` | Vanilla clouds | Transparent | Cloud texture/color |
| `gbuffers_weather` | Rain/snow | Transparent | Weather particles |
| `gbuffers_lightning` | Lightning | Additive | Lightning color |
| `gbuffers_skybasic` | Basic sky | Solid | Disabled sky fallback in legacy program classification |
| `gbuffers_skytextured` | Sky texture | Solid | Textured sky |
| `dh_water` | Distant Horizons water | Transparent | Distant water rendering |
| `physics_ocean` | Physics Mod ocean | Transparent | Mod-provided ocean geometry |

### Gbuffer Program Groups
### G-buffer Program Groups

The configured program sequence is grouped by geometry and blending behavior:

```
1. SOLID OPAQUE (depth test, no blend)
   ├─ gbuffers_terrain
   ├─ dh_terrain
   ├─ gbuffers_block (opaque)
   ├─ gbuffers_basic
   └─ gbuffers_line (GLSL 3.3 Core)

2. MIXED TRANSLUCENT (depth test, alpha blend)
   ├─ gbuffers_entities
   ├─ gbuffers_hand
   ├─ gbuffers_textured
   └─ gbuffers_particles

3. ADDITIVE/SPECIAL (no depth write, additive blend)
   ├─ gbuffers_armor_glint
   ├─ gbuffers_beaconbeam
   ├─ gbuffers_spidereyes
   └─ gbuffers_lightning

4. SKY/WEATHER (sky rendering)
   ├─ gbuffers_skytextured
   ├─ gbuffers_skybasic
   ├─ gbuffers_clouds
   ├─ gbuffers_weather
   └─ gbuffers_damagedblock

5. DISTANT HORIZONS (far terrain complement)
   ├─ dh_generic
   └─ dh_water

6. TRANSLUCENT FINALIZE
   └─ gbuffers_block (translucent)
   └─ gbuffers_water (final water)
   └─ gbuffers_physics_ocean (if installed)
```

Buffer ownership and producer/consumer lanes are documented in [BUFFERS.md](BUFFERS.md).

---

## Deferred Programs

### Purpose

Deferred programs read geometry/material data and produce screen-space shading results.

### Deferred Program Specifications

| Program | Main output | Role |
|---|---|---|
| `deferred` | `colortex2` | Screen-space ambient occlusion data when `SSAO` is enabled |
| `deferred1` | `colortex4` | Deferred material shading, fog, and supported reflection/cloud paths |

### Execution Details

The `deferred` program writes SSAO data when enabled. `deferred1` performs deferred material shading; its feature branches depend on settings and dimension macros.

---

## Composite Programs

### Purpose

Ordered post-processing programs. A program may read a buffer written several passes earlier; consult the source outputs and configured enable conditions rather than assuming each pass consumes the previous pass's output.

Programs execute in order, with enable conditions defined in `shaders.properties`. `composite1` ray-marches volumetric lighting into half-resolution `colortex0`; when volumetric lighting, shadow mapping, and the world-light path are active, it also reprojects temporal history through `colortex6`. `composite2` applies a 9-tap denoising filter and is disabled when volumetric lighting or shadow mapping is unavailable. `composite3` upsamples the result, applies fog, and adds it to the HDR scene.

### Composite Program Data Flow

| Stage | Main targets read | Main target written | Role |
|---|---|---|---|
| **Composite0** (`composite`) | Scene and material targets, depth | `colortex4` | Deferred and transparent complex shading |
| **Composite1** | Depth, optional `colortex6` history | Half-resolution `colortex0`, optional `colortex6` history | Volumetric ray marching and temporal accumulation |
| **Composite2** | `colortex0` | `colortex0` | 9-tap volumetric denoising when volumetrics and shadow mapping are enabled |
| **Composite3** | `colortex0`, `colortex4`, depth | `colortex4` | Upsample volumetrics and apply them with fog |
| **Composite4** | `colortex4`, temporal data when enabled | `colortex4`, optionally `colortex5` | TAA and temporal history |
| **Composite5** | `colortex3` | `colortex3` | FXAA for modes 1 and 3; copy otherwise |
| **Composite6** | `colortex4`, depth | `colortex4` | Motion blur |
| **Composite7** | `colortex4`, `depthtex1` | `colortex4` | Depth of field |
| **Composite8** | `colortex4` mip levels | Half-resolution `colortex0` | Bloom downsample |
| **Composite9-10** | `colortex0` | `colortex0` | Bloom blur |
| **Composite11** | `colortex0`, depth for lens-flare visibility | `colortex0` | Bloom upsampling and lens flare |
| **Composite12** | `colortex4`, `colortex0`, optional exposure history | `colortex3`, optionally `colortex5` | Final color composition |

### Composite Execution Details

**Sequential Dependency Chain**:
```
Composite1 ray-marches volumetrics into half-resolution colortex0 and optionally accumulates history in colortex6
Composite2 applies a 9-tap denoising filter to colortex0
Composite3 upsamples the volumetric result, applies fog, and adds it to colortex4
Composite4 performs TAA when enabled and updates temporal history
Composite8-11 process bloom through colortex0
Composite12 combines bloom with colortex4 and writes display-oriented output to colortex3
```

Passes execute in order, but adjacent programs can read and write different targets; see the data-flow table above.

**Key Stages Explained**:

- **Composite0**: Main deferred lighting pass, applies shadows to HDR scene
- **Composite1-3**: Ray-march volumetrics at half resolution, optionally accumulate temporal history, denoise, then upsample and apply to scene color
- **Composite4**: TAA and previous-frame data handling
- **Composite5**: FXAA, when selected by the anti-aliasing setting
- **Composite8-11**: Bloom downsample, blur, and upsampling; composite11 also handles lens flare
- **Composite12**: Final bloom application, auto exposure, tonemapping, vignette, color grading, and dithering

---

## Final Program

### Purpose

Final full-screen filtering and output to screen.

### Final Program Specifications

| Aspect | Value |
|--------|-------|
| Input Buffer | Final color is produced in `colortex3` by `composite12` |
| Output | Screen framebuffer |
| Processing | Retro filter, chromatic aberration, optional sharpening |
---

## Program File Organization

### Source Directory

```
shaders/
├── main/                       # Shared program implementations (.glsl)
│   ├── gbuffers/                # Geometry program implementations
│   ├── modded/                  # Mod integration implementations
│   ├── shadow/                  # Shadow program implementations
│   ├── composite*.glsl          # Composite0 through Composite12
│   ├── deferred*.glsl           # Deferred programs
│   └── final.glsl               # Final output program
└── world-X/                     # World-specific wrappers and settings
   ├── *.fsh / *.vsh            # Loader-facing program wrappers
   └── world.glsl               # Per-world settings
```

### Dimension-Specific Overrides

Each `world-X/` folder contains program wrappers with dimension-specific customizations:
- Different lighting properties
- Dimension-specific configuration; see [SETTINGS.md](SETTINGS.md) for macro definitions
- Optimized shadow parameters
- Customized color grading

See [SETTINGS.md](SETTINGS.md) for dimension configuration details.

---

## References

- **[ARCHITECTURE.md](ARCHITECTURE.md)** - Pipeline overview
- **[BUFFERS.md](BUFFERS.md)** - G-Buffer data packing
- **[FEATURES.md](FEATURES.md)** - Feature implementation details
- **[LEGACY.md](LEGACY.md)** - Original program classifications
