# Feature Catalog

This document summarizes the rendering features implemented by Super Duper Vanilla (SDV) and points to their source files. The shader source is authoritative for implementation details. UI labels, defaults, and value domains are documented in [SETTINGS.md](SETTINGS.md); stage order and program inputs/outputs are in [PROGRAMS.md](PROGRAMS.md).

## Materials and Surface Shading

| Feature | Description | Implementation |
|---|---|---|
| PBR workflows | Basic and Integrated PBR (materials inferred from vanilla albedo and block IDs) and LabPBR 1.3 resource-pack materials | [`integratedPBR.glsl`](../shaders/lib/PBR/integratedPBR.glsl), [`labPBR.glsl`](../shaders/lib/PBR/labPBR.glsl), [`dataStructs.glsl`](../shaders/lib/PBR/dataStructs.glsl) |
| GGX specular | Microfacet specular response with sun and moon shaped highlights (squircle, round, or the End black hole) | [`GGX.glsl`](../shaders/lib/lighting/GGX.glsl), [`complexShadingForward.glsl`](../shaders/lib/lighting/complexShadingForward.glsl), [`complexShadingLOD.glsl`](../shaders/lib/modded/distantHorizons+voxy/complexShadingLOD.glsl) |
| Environment materials | Rain makes upward-facing, low-porosity surfaces wetter, smoother, and darker | [`enviroPBR.glsl`](../shaders/lib/PBR/enviroPBR.glsl) |
| Generated normals | Optional normals generated from albedo height for terrain, water, and block entities (Integrated PBR) | [`integratedPBR.glsl`](../shaders/lib/PBR/integratedPBR.glsl) |
| Parallax occlusion and slope normals | Optional LabPBR height-based surface displacement, self-shadowing, and sharp slope normals at pixel edges | [`labPBR.glsl`](../shaders/lib/PBR/labPBR.glsl), terrain, entity, hand, and block Gbuffers |
| Emissive materials | Per-block and per-entity emission scaled by `EMISSIVE_INTENSITY` | PBR data handling, [`complexShadingForward.glsl`](../shaders/lib/lighting/complexShadingForward.glsl) |
| Subsurface scattering | Transmitted light for foliage, ice, snow, and other thin materials | [`complexShadingForward.glsl`](../shaders/lib/lighting/complexShadingForward.glsl) |
| Water, lava, and sculk materials | Noise-varied brightness, water normals, depth-based absorption, and foam | [`water.glsl`](../shaders/lib/surface/water.glsl), [`lava.glsl`](../shaders/lib/surface/lava.glsl), `gbuffers_water`, `gbuffers_terrain` |
| Portals | End portal star field, Nether portal edge glow, and Dimensional Doors portal | `gbuffers_block`, `gbuffers_water` |
| Unshaded fabric | Dimensional Doors fabric blocks render as pure texture colors with no normals | `gbuffers_terrain` |
| Color mode | Debug albedo modes: white, black, or foliage-only | `COLOR_MODE` branches in the Gbuffers programs |

These features are selected or parameterized by the PBR and material settings listed in [SETTINGS.md](SETTINGS.md).

## Lighting

| Feature | Description | Implementation |
|---|---|---|
| Shadow mapping | Direct-light visibility sampled in forward-shaded Gbuffers; falls back to lightmap-based fake shadows when disabled | [`shdDistort.glsl`](../shaders/lib/lighting/shdDistort.glsl), [`shdSample.glsl`](../shaders/lib/lighting/shdSample.glsl), [`shdSampleTexel.glsl`](../shaders/lib/lighting/shdSampleTexel.glsl), [`shdSampleVar.glsl`](../shaders/lib/lighting/shdSampleVar.glsl) |
| Colored shadows | Carries color from translucent shadow casters such as stained glass and water | Shadow programs and the shadow sampling functions above |
| Shadow filtering | Noise-rotated soft shadows with extra samples for subsurface materials | [`shdSample.glsl`](../shaders/lib/lighting/shdSample.glsl), [`complexShadingForward.glsl`](../shaders/lib/lighting/complexShadingForward.glsl) |
| SSAO | Four-sample screen-space ambient occlusion with a box blur | [`SSAO.glsl`](../shaders/lib/lighting/SSAO.glsl), `deferred.glsl`, `deferred1.glsl` |
| SSR and SSGI | Screen-space ray marching with binary refinement for reflections and experimental indirect light; rough reflections and previous-frame color are optional | [`rayTracer.glsl`](../shaders/lib/rayTracing/rayTracer.glsl), [`complexShadingDeferred.glsl`](../shaders/lib/lighting/complexShadingDeferred.glsl) |
| Directional lightmaps | Optional direction-aware block-light contribution for terrain and water | [`complexShadingForward.glsl`](../shaders/lib/lighting/complexShadingForward.glsl) |
| Underwater caustics | Water-surface cell noise modulates the colored shadow of water; requires `SHADOW_COLOR` | `shadow`, `shadow_water`, `physics_ocean_shadow`, [`water.glsl`](../shaders/lib/surface/water.glsl) |
| Basic and LOD lighting | Reduced lighting for simple programs and for Distant Horizons and Voxy terrain (no shadow map for LOD) | [`basicShadingForward.glsl`](../shaders/lib/lighting/basicShadingForward.glsl), [`complexShadingLOD.glsl`](../shaders/lib/modded/distantHorizons+voxy/complexShadingLOD.glsl) |

## Atmosphere and World Rendering

| Feature | Description | Implementation |
|---|---|---|
| Sky rendering | Sky color, stars, aether, sun and moon shapes, and the black hole celestial body, each toggled per dimension; also used for sky reflections | [`skyRender.glsl`](../shaders/lib/atmospherics/skyRender.glsl), [DIMENSION.md](DIMENSION.md) |
| Fog | Ground fog, border fog, rain and underwater density changes, and darkness fog | [`fogRender.glsl`](../shaders/lib/atmospherics/fogRender.glsl) |
| Volumetric lighting | Ray-marches shadow-map light at half resolution into `colortex0`, accumulates history in `colortex6`, then upsamples and adds it to the HDR scene | [`volumetricLight.glsl`](../shaders/lib/rayTracing/volumetricLight.glsl), `composite1.glsl`, `composite2.glsl`, `composite3.glsl` |
| Vanilla clouds | Vanilla cloud geometry with gradient shading when `CLOUD_TYPE` is `0` | `gbuffers_clouds` |
| Voxel clouds | DDA-traced voxel clouds read from a cloud map, with an optional second layer, weather response, and fade animation; replaces the older ray-marched `volumetricClouds.glsl`, which no program includes anymore | [`voxelClouds.glsl`](../shaders/lib/rayTracing/voxelClouds.glsl), `composite.glsl` |
| Terrain, water, and weather animation | Wind-driven and current-driven vertex displacement | [`waveTerrain.glsl`](../shaders/lib/vertex/waveTerrain.glsl), [`waveWater.glsl`](../shaders/lib/vertex/waveWater.glsl), [`weatherWave.glsl`](../shaders/lib/vertex/weatherWave.glsl) |
| World curvature | Optional downward bend of the world with distance, applied in vertex shaders | Vertex stages of the Gbuffers and shadow programs |
| Day cycle and timelapse | Light and sky colors are converted to linear space first, then blended across day, twilight, and night; timelapse smooths animations by world time | [DIMENSION.md](DIMENSION.md), custom uniforms in `shaders.properties` |
| Per-dimension configuration | Every dimension has the same full option set: feature flags, skylight, celestial body, vanilla fog color, star, light, sky, and fog settings for each time of day. All of it is exposed in the Configuration menu | [DIMENSION.md](DIMENSION.md), `shaders/world-X/world.glsl` files |

## Post-Processing

The listed composite numbers are the current SDV program assignments. Conditional program enablement is declared in `shaders/shaders.properties`. Volumetric lighting is covered in the table above.

| Feature | Program | Implementation |
|---|---|---|
| Temporal anti-aliasing | `composite4` | [`taa.glsl`](../shaders/lib/antialiasing/taa.glsl), [`taaJitter.glsl`](../shaders/lib/utility/taaJitter.glsl); Lite TAA + FXAA runs TAA without projection jitter |
| FXAA | `composite5` | [`fxaa.glsl`](../shaders/lib/antialiasing/fxaa.glsl) |
| Motion blur | `composite6` | [`motionBlur.glsl`](../shaders/lib/post/motionBlur.glsl) |
| Depth of field | `composite7` | Depth-aware mip-level sampling in the composite shader |
| Bloom | `composite8`-`composite12` | Mip-based tile downsample, separable Gaussian blur, tent-filter upsample, and luminance-weighted application |
| Lens flare | `composite11` | [`lensFlare.glsl`](../shaders/lib/post/lensFlare.glsl); shape follows the sun or moon type |
| Auto exposure | `composite13`, `composite14` | Center luminance sampled at a low mip level and smoothed in `colortex7` |
| Tone mapping and color grading | `composite14` | [`tonemap.glsl`](../shaders/lib/post/tonemap.glsl): modified Reinhard-Jodie extended tonemap, tint, exposure, contrast, saturation, dithering |
| Vignette | `composite14` | Radial darkening in the composite shader |
| Outlines | `deferred1` | [`outline.glsl`](../shaders/lib/post/outline.glsl): Standard or Dungeons style |
| Retro filter, chromatic aberration, sharpening | `final` | Final program in `shaders/main/final.glsl` |

For the full pass map and buffer I/O, see [PROGRAMS.md](PROGRAMS.md) and [BUFFERS.md](BUFFERS.md).

## Integrations

- **Distant Horizons**: dedicated terrain, generic geometry, and water programs. LOD terrain uses noise-varied colors and the simplified LOD shading path.
- **Voxy**: `voxy.json` plus opaque and translucent fragment programs using Voxy's material IDs and depth inputs.
- **Physics Mod**: ocean geometry and shadow programs, controlled by `PHYSICS_OCEAN_SUPPORT`; adds ocean displacement and physics foam.
- **Dimensional Doors**: dedicated dimension folders for pockets, Limbo, and personal pockets, unshaded fabric blocks, and a custom portal.
- **Wildcard dimension**: `world999` applies to any dimension not listed in `dimension.properties`, such as modded dimensions. It has its own full settings screen and defaults to the Overworld look.

Provider/loader availability is cataloged in [PROGRAMS.md](PROGRAMS.md). Settings and exact menu labels are in [SETTINGS.md](SETTINGS.md).