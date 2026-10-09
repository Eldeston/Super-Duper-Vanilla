# Feature Catalog

This document summarizes the rendering features implemented by Super Duper Vanilla (SDV) and points to their source files. The shader source is authoritative for implementation details. UI labels, defaults, and value domains are documented in [SETTINGS.md](SETTINGS.md); stage order and program inputs/outputs are in [PROGRAMS.md](PROGRAMS.md).

## Materials and Surface Shading

| Feature | Description | Implementation |
|---|---|---|
| PBR workflows | Integrated PBR for vanilla-style material classification and LabPBR resource-pack materials | [`integratedPBR.glsl`](../shaders/lib/PBR/integratedPBR.glsl), [`labPBR.glsl`](../shaders/lib/PBR/labPBR.glsl), [`dataStructs.glsl`](../shaders/lib/PBR/dataStructs.glsl) |
| GGX specular | Microfacet specular response used by the shading paths | [`GGX.glsl`](../shaders/lib/lighting/GGX.glsl), [`complexShadingForward.glsl`](../shaders/lib/lighting/complexShadingForward.glsl), [`complexShadingDeferred.glsl`](../shaders/lib/lighting/complexShadingDeferred.glsl) |
| Environment materials | Material response can vary with environmental conditions | [`enviroPBR.glsl`](../shaders/lib/PBR/enviroPBR.glsl) |
| Normal generation and slope normals | Optional normal sources for supported materials | [`integratedPBR.glsl`](../shaders/lib/PBR/integratedPBR.glsl), terrain and block Gbuffers |
| Parallax occlusion | Optional LabPBR height-based surface displacement and self-shadowing | [`labPBR.glsl`](../shaders/lib/PBR/labPBR.glsl), terrain/entity/hand/block Gbuffers |
| Emissive materials | Material emissive values contribute to scene shading | PBR data handling and [`complexShadingForward.glsl`](../shaders/lib/lighting/complexShadingForward.glsl) |
| Subsurface scattering | Adds a transmitted-light contribution for supported thin materials | [`complexShadingForward.glsl`](../shaders/lib/lighting/complexShadingForward.glsl) |
| Water and lava materials | Material helpers for water and lava appearance | [`water.glsl`](../shaders/lib/surface/water.glsl), [`lava.glsl`](../shaders/lib/surface/lava.glsl) |

These features are selected or parameterized by the PBR and material settings listed in [SETTINGS.md](SETTINGS.md).

## Lighting

| Feature | Description | Implementation |
|---|---|---|
| Shadow mapping | Uses the shadow depth target for direct-light visibility | [`shdDistort.glsl`](../shaders/lib/lighting/shdDistort.glsl), [`shdSample.glsl`](../shaders/lib/lighting/shdSample.glsl), [`shdSampleTexel.glsl`](../shaders/lib/lighting/shdSampleTexel.glsl), [`shdSampleVar.glsl`](../shaders/lib/lighting/shdSampleVar.glsl) |
| Colored shadows | Carries shadow color from supported translucent shadow casters | Shadow programs and the shadow sampling functions above |
| Shadow filtering | Optional filtering path used by forward and deferred shading | [`complexShadingForward.glsl`](../shaders/lib/lighting/complexShadingForward.glsl), [`complexShadingDeferred.glsl`](../shaders/lib/lighting/complexShadingDeferred.glsl) |
| SSAO | Computes screen-space ambient occlusion from scene depth | [`SSAO.glsl`](../shaders/lib/lighting/SSAO.glsl), `shaders/main/deferred.glsl` |
| SSR and SSGI | Screen-space ray tracing for reflections and experimental indirect-light accumulation | [`rayTracer.glsl`](../shaders/lib/rayTracing/rayTracer.glsl), deferred shading |
| Directional lightmaps | Optional direction-aware lightmap contribution | Forward shading and terrain/entity Gbuffers |
| Underwater caustics | Caustic contribution for underwater rendering; the setting requires shadow color | Lighting and water Gbuffers |

## Atmosphere and World Rendering

| Feature | Description | Implementation |
|---|---|---|
| Sky rendering | Computes sky and atmospheric color contributions | [`skyRender.glsl`](../shaders/lib/atmospherics/skyRender.glsl) |
| Fog | Ground/atmospheric fog and border fog | [`fogRender.glsl`](../shaders/lib/atmospherics/fogRender.glsl) |
| Volumetric lighting | Renders at half resolution to `colortex0`, then is upsampled into the HDR scene | [`volumetricLight.glsl`](../shaders/lib/rayTracing/volumetricLight.glsl), `composite2.glsl`, `composite3.glsl` |
| Voxel clouds | Screen-space voxel-cloud rendering for the selected cloud mode | [`voxelClouds.glsl`](../shaders/lib/rayTracing/voxelClouds.glsl), deferred shading |
| Volumetric clouds | Ray-marched volumetric cloud contribution where enabled | [`volumetricClouds.glsl`](../shaders/lib/rayTracing/volumetricClouds.glsl) |
| Terrain, water, and weather animation | Vertex displacement and animated weather behavior | [`waveTerrain.glsl`](../shaders/lib/vertex/waveTerrain.glsl), [`waveWater.glsl`](../shaders/lib/vertex/waveWater.glsl), [`weatherWave.glsl`](../shaders/lib/vertex/weatherWave.glsl) |
| Dimension-specific lighting | World flags and color/fog constants select per-dimension behavior | `shaders/world-X/world.glsl` files |

## Post-Processing

The listed composite numbers are the current SDV program assignments. Conditional program enablement is declared in `shaders/shaders.properties`.

| Feature | Program | Implementation |
|---|---|---|
| Temporal anti-aliasing | `composite4` | [`taa.glsl`](../shaders/lib/antialiasing/taa.glsl) |
| FXAA | `composite5` | [`fxaa.glsl`](../shaders/lib/antialiasing/fxaa.glsl) |
| Motion blur | `composite6` | [`motionBlur.glsl`](../shaders/lib/post/motionBlur.glsl) |
| Depth of field | `composite7` | Depth-aware mip-level sampling in the composite shader |
| Bloom | `composite8`-`composite12` | Half-resolution bloom downsample, blur, upsample, and composition |
| Lens flare | `composite11` and `composite12` | [`lensFlare.glsl`](../shaders/lib/post/lensFlare.glsl) |
| Tone mapping and color grading | `composite12` | [`tonemap.glsl`](../shaders/lib/post/tonemap.glsl) |
| Outlines | `deferred1` | [`outline.glsl`](../shaders/lib/post/outline.glsl) |
| Retro filter, chromatic aberration, sharpening | `final` | Final program in `shaders/main/final.glsl` |

`composite1` is currently a disabled no-op. For the full pass map and buffer I/O, see [PROGRAMS.md](PROGRAMS.md); for target reuse, see [BUFFERS.md](BUFFERS.md).

## Integrations

- **Distant Horizons**: dedicated terrain, generic geometry, and water programs.
- **Voxy**: alternate opaque/translucent depth inputs in supported paths.
- **Physics Mod**: ocean geometry and shadow programs, controlled by `PHYSICS_OCEAN_SUPPORT`.

Provider/loader availability is cataloged in [PROGRAMS.md](PROGRAMS.md). Settings and exact menu labels are in [SETTINGS.md](SETTINGS.md).
