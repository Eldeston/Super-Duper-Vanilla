# Buffer Main Bus

**Related documents**: [ARCHITECTURE.md](ARCHITECTURE.md) for stage context; [PROGRAMS.md](PROGRAMS.md) for program definitions and enable conditions.

A lane represents a render target. A station represents a shader program reading from or writing to that lane. The bus below follows the 1.3.9 shader sources and `shaders.properties`; optional stations run only when their feature is enabled.

SDV uses **eight color targets** (`colortex0` to `colortex7`). Formats are declared in the commented settings block of `shaders/main/final.glsl`; buffer sizes and clear behavior come from `shaders/shaders.properties` and `final.glsl`.

## Color-Target Main Bus

```mermaid
flowchart TB
    subgraph BUS["Color-target main bus"]
        direction TB

        subgraph L0["Lane: colortex0 · half resolution"]
            direction LR
            C1W["Composite1<br/>W: volumetric ray march"] --> C2RW["Composite2<br/>R/W: temporal accumulation"] --> C3R["Composite3<br/>R: upsample input"] --> C8W["Composite8<br/>W: bloom tiles"] --> C9["Composite9<br/>R/W: horizontal blur"] --> C10["Composite10<br/>R/W: vertical blur"] --> C11["Composite11<br/>R/W: bloom upsample + lens flare"] --> C12R["Composite12<br/>R: bloom input"]
        end

        subgraph L1["Lane: colortex1 · normals"]
            direction LR
            G1W["Gbuffers<br/>W: surface normals"] --> DR1["Deferred / Deferred1<br/>R: SSAO, reflections, outlines"] --> C0R1["Composite0<br/>R: reflections on forward geometry"]
        end

        subgraph L2["Lane: colortex2 · albedo + AO"]
            direction LR
            G2W["Gbuffers<br/>W: albedo"] --> DW2["Deferred<br/>R/W: SSAO in alpha"] --> D1R2["Deferred1<br/>R: albedo, blurred SSAO"] --> C0R2["Composite0<br/>R: albedo"]
        end

        subgraph L3["Lane: colortex3 · material / post color"]
            direction LR
            G3W["Gbuffers<br/>W: metallic, smoothness, mask"] --> D1R3["Deferred1<br/>R: material"] --> C0R3["Composite0<br/>R: material + mask"] --> C14W["Composite14<br/>W: final post color"] --> FINAL["Final<br/>R: display color"]
        end

        subgraph L4["Lane: colortex4 · HDR scene"]
            direction LR
            G4W["Gbuffers<br/>W: forward scene"] --> D1RW4["Deferred1<br/>R/W: reflections, sky, fog"] --> C0RW4["Composite0<br/>R/W: forward geometry + clouds"] --> C3RW4["Composite3<br/>R/W: add volumetrics"] --> C4RW4["Composite4<br/>R/W: TAA"] --> C5RW4["Composite5<br/>R/W: FXAA when selected"] --> C6RW4["Composite6<br/>R/W: motion blur"] --> C7RW4["Composite7<br/>R/W: DOF"] --> C8R4["Composite8<br/>R: bloom source (mips)"] --> C12RW4["Composite12<br/>R/W: apply bloom"] --> C13R4["Composite13<br/>R: exposure sample"] --> C14R4["Composite14<br/>R: tonemapping"]
        end

        subgraph L5["Lane: colortex5 · previous-frame color"]
            direction LR
            C4W5["Composite4<br/>W: scene color after TAA"] --> NEXT["Next frame<br/>R: TAA history, SSR/SSGI"]
        end

        subgraph L6["Lane: colortex6 · volumetric history · half resolution"]
            direction LR
            C2RW6["Composite2<br/>R/W: volumetric history"]
        end

        subgraph L7["Lane: colortex7 · auto exposure"]
            direction LR
            C13RW7["Composite13<br/>R/W: exposure state"] --> C14R7["Composite14<br/>R: exposure"]
        end
    end
```

**Legend**: `R` = read, `W` = write, `R/W` = read and write. The arrows show data movement within a lane, not every shader execution dependency. For exact program conditions see [PROGRAMS.md](PROGRAMS.md).

## Lane Specifications

| Lane | Format | Payload and lifecycle | Size | Clear |
|---|---|---|---|---|
| `colortex0` | `R11F_G11F_B10F` | Half-resolution volumetrics, then bloom intermediates. A cloud-map texture is also bound here when `CLOUD_TYPE != 0` | `0.5 × 0.5` | No |
| `colortex1` | `RGB16_SNORM` | Surface normals. All-zero normals mean "no normal" and are skipped by SSAO and outlines | Full | `(0, 0, 0, 1)` |
| `colortex2` | `RGBA8` | Albedo in RGB; SSAO in alpha after `deferred` | Full | No |
| `colortex3` | `RGB8` | Metallic (R), smoothness (G), shading mask (B); later reused for post-processed color | Full | Default |
| `colortex4` | `R11F_G11F_B10F` | HDR scene color through shading and post-processing | Full | `(0, 0, 0, 1)` |
| `colortex5` | `R11F_G11F_B10F` | Previous-frame scene color for TAA, SSR, and SSGI | Full | No |
| `colortex6` | `RGB8` | Half-resolution volumetric history | `0.5 × 0.5` | No |
| `colortex7` | `R16F` | Auto exposure state, read from texel `(0, 0)` | `1 × 1` | No |

`shadowcolor0` is `RGB8` and is not cleared. Do not disable the clears of `colortex1` and `colortex4`: the source notes they prevent beacon SSAO artifacts and sky silhouette artifacts.

`colortex7` is a single texel (`size.buffer.colortex7 = 1 1` in `shaders.properties`).

## The Shading Mask (`colortex3`, blue channel)

Gbuffers programs write a mask value in the blue channel of `colortex3` that later passes use to decide who shades a pixel.

| Value | Meaning | Written by |
|---|---|---|
| `0` | Opaque geometry shaded in `deferred1` | `gbuffers_terrain`, `gbuffers_basic`, `dh_terrain`, `voxy_opaque`, and pixels no program wrote (default clear) |
| `0.5` | Forward-shaded geometry handled by `composite` | `gbuffers_water`, `gbuffers_block`, `gbuffers_entities`, `gbuffers_hand`, `gbuffers_particles`, `gbuffers_textured`, `dh_water`, `voxy_translucent`, `physics_ocean` |

`composite` applies reflections and fog only where the mask is strictly between `0` and `1`. Material blue is not a physical value.

## Gbuffer Output Sets

Which targets each gbuffer-stage program writes, from each program's `RENDERTARGETS` declaration.

| Targets written | Programs |
|---|---|
| `4, 1, 2, 3` (scene, normal, albedo, material) | `gbuffers_terrain`, `gbuffers_block`, `gbuffers_entities`, `gbuffers_hand`, `gbuffers_water`, `physics_ocean`, `dh_terrain`, `dh_water`, `voxy_opaque`, `voxy_translucent` |
| `4, 3` (scene, material) | `gbuffers_basic`, `gbuffers_particles`, `gbuffers_textured` |
| `4` (scene only) | `gbuffers_clouds`, `gbuffers_skytextured`, `gbuffers_weather`, `gbuffers_line`, `gbuffers_armor_glint`, `gbuffers_beaconbeam`, `gbuffers_spidereyes`, `gbuffers_damagedblock`, `gbuffers_lightning`, `dh_generic` |

## Pipeline Passes by Lane

| Pass | Reads | Writes | Notes |
|---|---|---|---|
| `deferred` | `colortex1`, `colortex2`, `depthtex0` | `colortex2` | SSAO into alpha; default alpha `0.25` |
| `deferred1` | `colortex1`, `colortex2`, `colortex3`, `colortex4`, `colortex5`, `depthtex0` | `colortex4` | Sky, SSR/SSGI reflections, outlines, SSAO application, fog |
| `composite` | `colortex0` (cloud map), `colortex1` to `colortex5` | `colortex4` | Forward-shaded geometry reflections and fog; voxel clouds |
| `composite1` | `depthtex0`, `shadowtex0`, `shadowtex1`, `shadowcolor0` | `colortex0` | Half-resolution volumetric ray march |
| `composite2` | `colortex0`, `colortex6`, `depthtex0` | `colortex0`, `colortex6` | Temporal accumulation (`0.1` current, `0.9` history) |
| `composite3` | `colortex0`, `colortex4`, `depthtex0` | `colortex4` | Upsample (nearest, `fragCoord * 0.5`), apply, clamp to non-negative |
| `composite4` | `colortex4`, `colortex5`, `depthtex0` | `colortex4`, `colortex5` | TAA; writes previous-frame color |
| `composite5` | `colortex4` | `colortex4` | FXAA on the HDR scene (modes 1 and 3) |
| `composite6` | `colortex4`, `depthtex0` | `colortex4` | Motion blur |
| `composite7` | `colortex4` (mips), `depthtex1` | `colortex4` | Depth of field |
| `composite8` | `colortex4` (mips) | `colortex0` | Bloom tile downsample |
| `composite9`-`10` | `colortex0` | `colortex0` | Horizontal then vertical blur |
| `composite11` | `colortex0` | `colortex0` | Bloom upsample, lens flare |
| `composite12` | `colortex4`, `colortex0` | `colortex4` | Apply bloom |
| `composite13` | `colortex4` (LOD 8), `colortex7` | `colortex7` | Auto exposure (when enabled) |
| `composite14` | `colortex4`, `colortex7` | `colortex3` | Tonemap, grading, dithering |
| `final` | `colortex3` | Screen | Retro, chromatic aberration, sharpening |

## Attachment Side Lanes

These depth and shadow attachments feed the color-target stations but are not color-target lanes.

| Attachment | Producer | Main consumers | Role |
|---|---|---|---|
| `depthtex0` | Gbuffers | Deferred, `deferred1`, `composite`, `composite1` to `composite4`, `composite6`, lens flare, outlines, SSR | Depth including translucents |
| `depthtex1` | Gbuffers | `composite7` (DOF), `gbuffers_water`, `physics_ocean` | Depth without translucents (water depth and foam) |
| `shadowtex0` | Shadow programs | Forward-shaded gbuffers, `basicShadingForward`, `composite1` | Shadow depth |
| `shadowtex1` | Shadow programs | Same as above when `SHADOW_COLOR` is enabled | Depth without translucent casters |
| `shadowcolor0` | Shadow programs | Same as above when `SHADOW_COLOR` is enabled | Colored shadow data and caustics |
| `dhDepthTex0`, `dhDepthTex1` | Distant Horizons | `deferred1`, `composite`, `composite1`, `composite3`, `dh_water` | LOD depth (used where the vanilla depth is sky) |
| `vxDepthTexOpaque`, `vxDepthTexTrans` | Voxy | Same passes; `voxy_translucent` | LOD depth and water depth |

Direct lighting and shadow-map sampling are done forward in the gbuffers programs (and in `composite1` for volumetrics). The deferred passes handle reflections, SSGI, SSAO, outlines, sky, and fog and do not sample the shadow map.

## Lane Rules

- Buffer reuse is intentional. Iris is limited to 16 render targets, so lanes are multipurposed instead of adding more. `colortex0` is a reused intermediate: volumetrics use it before bloom reuses it later in the frame.
- `colortex4` has mipmaps enabled where needed (`composite7` for DOF, `composite8` for bloom, `composite13` for exposure).
- `colortex5` is written by `composite4` only when TAA is selected or when `PREVIOUS_FRAME` is on with SSR or SSGI. It holds the scene after TAA but before FXAA, motion blur, DOF, bloom, and tonemapping, so previous-frame reflections include volumetrics but no post effects.
- `colortex6` is only written when volumetric lighting, shadow mapping, and the world-light path are active. At `RGB8` precision the history is quantized to 8 bits.
- `colortex7` is only updated when `AUTO_EXPOSURE` is enabled.
- When `CLOUD_TYPE != 0`, `shaders.properties` binds `textures/clouds.png` to `colortex0` for the `composite` and `deferred` stages (`texture.composite.colortex0`, `texture.deferred.colortex0`). It is read by `voxelClouds.glsl`. The cloud map is overwritten safely by later passes and is never used for history storage.- `colortex3` changes role after `deferred1` and `composite` consume the material data; `composite14` then writes final post color into it for `final`.