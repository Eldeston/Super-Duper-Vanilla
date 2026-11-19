# Optimization Guide

This guide is for developers who contribute to or study the Super Duper Vanilla (SDV) codebase. It explains how SDV is configured and written to stay cheap, how to recognize what an effect costs, and how to measure a change. [CONTRIBUTION.md](../CONTRIBUTION.md) requires testing the shader before submitting a pull request, optimizing code wherever possible, and adding comments when necessary.

Excerpts below are taken from the 1.3.9 source; larger code is referenced by file. This guide contains no measured timings. Cost descriptions are qualitative (what an effect scales with) until captures are recorded in [Measured Results](#measured-results).

## Contents

1. [Profiling and Measurement](#profiling-and-measurement)
2. [Pipeline-Level Optimization](#pipeline-level-optimization)
3. [Direct Optimization Techniques](#direct-optimization-techniques)
4. [Advanced Optimization Techniques](#advanced-optimization-techniques)
5. [Cost Map](#cost-map)
6. [Review Checklist](#review-checklist)
7. [Open Optimization Work](#open-optimization-work)
8. [Measured Results](#measured-results)

---

## Profiling and Measurement

For buffer debugging and execution-time profiling, use [GFX Debuggers](https://modrinth.com/mod/gfx-debuggers) with either [NVIDIA Nsight Graphics](https://developer.nvidia.com/nsight-graphics) or [RenderDoc](https://renderdoc.org/). Setup is covered by each tool's own documentation. Treat every capture as specific to the tested hardware, driver, scene, resolution, and settings.

### Measurement Procedure

1. Select a repeatable scene and keep view position, render resolution, render distance, weather, and time of day fixed.
2. Allow shader compilation and scene loading to finish before recording a baseline.
3. Record frame time with the same method for every comparison. Compare frame time, not FPS, and use consistent capture windows because averages can hide stutter.
4. Change one setting or one piece of code at a time, then repeat the same capture.
5. Record the changed setting, scene, resolution, profile, and observed frame time with the result.

### Isolating a Workload

- Use the settings and profiles in [SETTINGS.md](SETTINGS.md) to toggle features independently: `SHADOW_MAPPING`, `VOLUMETRIC_LIGHTING`, `SSAO`, `SSR`, `SSGI`, `BLOOM`, `DOF`, `MOTION_BLUR`, and so on.
- Use the pass map in [PROGRAMS.md](PROGRAMS.md) and the buffer lanes in [BUFFERS.md](BUFFERS.md) to match a captured pass to its source program.
- If frame time changes between captures, check for changed scene content, shader compilation, background work, or different capture conditions before attributing the change to a setting.

### Interpreting Results

- If changing `shadowMapResolution` changes frame time, the shadow-map workload contributes to the scene. Pixel count grows with the square of the resolution.
- If changing `RAYTRACER_STEPS` or `RAYTRACER_BISTEPS` changes frame time, screen-space ray traversal contributes.
- If changing the render resolution changes frame time substantially, full-resolution gbuffers or full-screen passes are significant. The half-resolution `colortex0` and `colortex6` reduce the pixel count of volumetrics and bloom.

---

## Pipeline-Level Optimization

Many of SDV's savings come from configuration rather than shader math: which buffers exist, how big they are, which programs run, and what the loader does for free.

### Render Targets

SDV declares its buffer formats in the commented settings block of `shaders/main/final.glsl`:

```glsl
const int shadowcolor0Format = RGB8;

const int colortex0Format = R11F_G11F_B10F;
const int colortex1Format = RGB16_SNORM;
const int colortex2Format = RGBA8;
const int colortex3Format = RGB8;
const int colortex4Format = R11F_G11F_B10F;
const int colortex5Format = R11F_G11F_B10F;
const int colortex6Format = RGB8;
const int colortex7Format = R16F;
```

Sizes come from `shaders/shaders.properties`:

```properties
size.buffer.colortex0 = 0.5 0.5
size.buffer.colortex6 = 0.5 0.5
size.buffer.colortex7 = 1 1
```

| Target | Format | Nominal bits per texel | Size | Bits per screen pixel |
|---|---|---:|---|---:|
| `colortex0` | `R11F_G11F_B10F` | 32 | Half | 8 |
| `colortex1` | `RGB16_SNORM` | 48 | Full | 48 |
| `colortex2` | `RGBA8` | 32 | Full | 32 |
| `colortex3` | `RGB8` | 24 | Full | 24 |
| `colortex4` | `R11F_G11F_B10F` | 32 | Full (plus mip chain) | 32 |
| `colortex5` | `R11F_G11F_B10F` | 32 | Full | 32 |
| `colortex6` | `RGB8` | 24 | Half | 6 |
| `colortex7` | `R16F` | 16 | Single texel | ~0 |

The nominal total is 182 bits (about 22.75 bytes) per screen pixel, before depth textures, mip chains, and driver behavior. Drivers may pad three-channel formats, and Iris can keep an alternate texture per target for passes that read and write the same lane, so confirm actual VRAM use in your profiler rather than relying on this table.

What the format choices buy:

- **`R11F_G11F_B10F` for HDR color** keeps full HDR range in 32 bits per texel, half the size of an `RGBA16F` target.
- **Half-resolution `colortex0` and `colortex6`** cut volumetrics and bloom to a quarter of the pixel count.
- **`colortex7` is a single texel** because auto exposure needs one value (see `composite13.glsl`).
- **Reuse instead of new targets.** Iris is limited to 16 render targets, so lanes are multipurposed across the frame: `colortex0` holds volumetrics, then bloom; `colortex3` holds material data, then final color. See [BUFFERS.md](BUFFERS.md).
- **Clear flags.** Targets that are fully overwritten or that carry history are not cleared, which saves clear bandwidth. The block in `final.glsl` disables clears for `shadowcolor0`, `colortex0`, `colortex2`, `colortex5`, `colortex6`, and `colortex7`, and keeps clears on `colortex1` and `colortex4` because disabling them produces artifacts.
- **Mipmaps only where read.** `colortex4MipmapEnabled` is declared only in `composite7.glsl` (depth of field) and `composite8.glsl` (bloom); `composite13.glsl` also samples a low mip for exposure. Do not enable mipmaps on a target no pass samples at a lower level.

### Shadow Settings

| Setting | Default | Effect on cost |
|---|---|---|
| `shadowMapResolution` | `1024` | Texel count grows with the square of the resolution; `shadowcolor0` alone is nominally 3 MiB at 1024, 12 MiB at 2048, and 48 MiB at 4096 |
| `shadowDistance` | `128.0` | Larger distances render more geometry into the shadow map and stretch its resolution |
| `shadowDistanceRenderMul` | `1.0` | Hardcoded to `1.0` for maximum optimization |
| `entityShadowDistanceMul` | `0.5` | Entity shadows render at half the shadow distance (Iris) |
| `shadowHardwareFiltering` | `true` | Free slightly better filtering from the shadow sampler |
| `ENTITY_SHADOWS`, `BLOCK_ENTITY_SHADOWS` | On | Turn `shadowEntities` and `shadowBlockEntities` off in `shaders.properties` when disabled |
| `SHADOW_COLOR`, `SHADOW_FILTER` | On | Colored shadows need `shadowtex1` and `shadowcolor0`; filtering adds samples per pixel |

The shadow distortion in [`shdDistort.glsl`](../shaders/lib/lighting/shdDistort.glsl) gives nearby geometry more shadow-map resolution so a given resolution goes further. All shadow programs are moved off screen and discarded when `WORLD_LIGHT` or `SHADOW_MAPPING` is not defined, so shadow rendering costs nothing in dimensions without a sun or when shadows are off. The volumetric pass limits its ray length with `min(shadowDistance, ...)`.

Two sampling paths exist on purpose: [`shdSample.glsl`](../shaders/lib/lighting/shdSample.glsl) uses a hardware shadow sampler for per-pixel lighting, and [`shdSampleTexel.glsl`](../shaders/lib/lighting/shdSampleTexel.glsl) does a manual depth compare with `texelFetch` for the volumetric ray march, where many samples are taken per pixel.

### Program Settings in `shaders.properties`

**Culling and depth**

| Property | Value | Purpose |
|---|---|---|
| `shadow.culling` | `true` | Culls geometry that cannot affect the shadow map |
| `frustum.culling` | `true` | Culls geometry outside the view frustum |
| `occlusion.culling` | `true` | Iris occlusion culling |
| `rain.depth` | `false` | Rain does not write depth |

**Skipping vanilla draws**

`sky`, `stars`, and (unless `SUN_MOON_TYPE` is `2`) `sun` and `moon` are set to `false` because SDV renders them in screen space. `dhClouds = off` and `dhShadow.enabled = false` skip Distant Horizons clouds and shadows.

**Blending and alpha testing**

Blending is turned off for most programs (`blend.gbuffers_terrain = off`, `blend.shadow = off`, and so on), and additive blending is set only where needed (`ONE ONE ZERO ZERO` for glint, textured sky, spider eyes, and lightning). Translucent gbuffers programs turn blending off on the non-color attachments, since normals, albedo, and material data should replace rather than blend:

```properties
blend.gbuffers_water.colortex1 = off
blend.gbuffers_water.colortex2 = off
blend.gbuffers_water.colortex3 = off
```

Alpha testing is disabled for every program (`alphaTest.gbuffers_terrain = off`, and so on) and done manually in the shader against `ALPHA_THRESHOLD`, so the pack controls exactly when a pixel is discarded.

**Disabling programs**

Composite and deferred programs are disabled when their feature is off. The condition is repeated for each dimension folder:

```properties
#if !defined VOLUMETRIC_LIGHTING || !defined SHADOW_MAPPING
    program.world-4/composite2.enabled = false
    program.world-3/composite2.enabled = false
    ...
#endif
```

The conditions for each pass are tabulated in [PROGRAMS.md](PROGRAMS.md#composite-programs).

There are no `enabled` settings for gbuffers programs. Disabling a gbuffers program makes Iris fall back to its vanilla program, which writes to the wrong buffers and breaks the pipeline. Instead, SDV neutralizes a gbuffers or shadow program in its own source by moving the geometry off screen in the vertex shader and discarding in the fragment shader:

```glsl
void main(){
    gl_Position = vec4(-10);
}
```

```glsl
void main(){
    discard; return;
}
```

(`gbuffers_skybasic.glsl` and `shadow_lightning.glsl` are completely disabled this way. `gbuffers_clouds`, `gbuffers_weather`, and the shadow programs apply the same pattern conditionally through their feature macros.)

**Custom uniforms computed once per frame**

Values that are the same for every pixel are computed in `shaders.properties` instead of in the shaders:

```properties
uniform.float.shdFade = min(absCelestialSinX * pi * 2, 1)
uniform.float.dayCycle = 1 + celestialSinX
```

The full list is in [ARCHITECTURE.md](ARCHITECTURE.md#custom-uniforms).

---

## Direct Optimization Techniques

These are small, local changes. Each is cheap to apply and none replaces profiling.

### Fetch Instead of Sample

When reading a texture one-to-one with the screen, `texelFetch` skips coordinate normalization and filtering. Most composite passes read the scene this way:

```glsl
ivec2 screenTexelCoord = ivec2(gl_FragCoord.xy);
sceneColOut = texelFetch(colortex4, screenTexelCoord, 0).rgb;
```

Reading a half-resolution buffer from a full-resolution pass is a nearest-neighbor fetch with a scaled coordinate (`composite3.glsl`):

```glsl
sceneColOut += texelFetch(colortex0, ivec2(gl_FragCoord.xy * 0.5), 0).rgb * lightCol * volumetricFogDensity;
```

Noise lookups wrap with a bit mask instead of `mod` or `fract`: `getRng2(screenTexelCoord & 255)`.

### Cheaper Math

`shaders/lib/utility/common.glsl` holds the helpers SDV uses everywhere:

```glsl
// Squared functions x ^ 2
float squared(in float x){ return x * x; }

// Cubed functions x^3
float cubed(in float x){ return x * x * x; }

// Faster normalize using inversesqrt()
vec3 fastNormalize(in vec3 x){ return x * inversesqrt(lengthSquared(x)); }

// Fast approximate sqrt for 0-1 range
float fastSqrt(in float x){ return x * (2.0 - x); }
```

General rules the codebase follows:

- Write `x * x` instead of `pow(x, 2.0)`, and `x * x * x` instead of `pow(x, 3.0)`.
- Compare `lengthSquared` values instead of lengths where possible, and use `inversesqrt` instead of `1.0 / sqrt()`.
- Multiply by a precomputed reciprocal instead of dividing: `0.00392156863` instead of `/ 255.0`, and constants such as `shadowMapPixelSize` and `shadowDistanceInv`.
- Replace `pow` with a polynomial where an approximation is acceptable. The sRGB conversions avoid `pow(x, 2.2)`:

```glsl
// SRGB to linear
float toLinear(in float x){ return ((2.10545 + x) * (0.0231872 + x)) * x * 0.315206; }
// Linear to SRGB
float toSRGB(in float x){ return (inversesqrt(x) - 0.126893) * x * 1.14374; }
```

### Compile-Time Work

- **Precalculated constants.** The block at the end of `shaders/lib/settings.glsl` turns settings into constants once, such as `worldCurvatureInv`, `waterTileSizeInv`, and `sunMoonIntensitySqrd`.
- **Preprocessor over runtime branches.** Features are gated with `#ifdef`, `#if defined`, and `#if SETTING == value` so disabled code is not compiled, and its uniforms and samplers are not even declared. Every composite program follows this pattern.
- **Constant loop bounds.** Loop counts come from macros as constants, such as `const uint rayTraceSteps = uint(RAYTRACER_STEPS);`, so the compiler can unroll or schedule them.

### Loops

Compute everything that does not change per iteration before the loop and step incrementally inside it. The volumetric light march (`shaders/lib/rayTracing/volumetricLight.glsl`) builds the step vector and start position once, converted to shadow space, so the loop only samples and adds:

```glsl
vec3 endPos = vec3(shadowProjection[0].x, shadowProjection[1].y, shadowProjection[2].z) * (mat3(shadowModelView) * nFeetPlayerPos);
endPos *= rayLength * dynamicVolumetricLightStepsInv;

vec3 startPos = vec3(shadowProjection[0].x, shadowProjection[1].y, shadowProjection[2].z) * shadowModelView[3].xyz + endPos * dither;
startPos.z += shadowProjection[3].z;

for(uint i = 0u; i < dynamicVolumetricLightSteps; i++){
    // No need to do anymore fancy matrix multiplications during the loop
    volumeData += getShdCol(getShdDistort(startPos));
    // We continue tracing!
    startPos += endPos;
}
```

The same code also shows two more techniques:

- **Use only the matrix terms you need.** The shadow projection is orthographic, so only its diagonal and the `z` translation are used instead of a full `mat4` multiply. Vertex shaders do the same with `getMatScale(mat3(gl_ProjectionMatrix))`.
- **Dynamic step counts.** The number of steps shrinks for short rays: `clamp(uint(rayLength * VOLUMETRIC_LIGHT_STEPS), 1u, VOLUMETRIC_LIGHT_STEPS)`.

### Dither Instead of More Samples

Where a loop would need many samples for smooth results, SDV takes few samples with a per-pixel dither offset (interleaved gradient noise, `IGN()` in `noiseFunctions.glsl`, or blue noise from `noisetex`) and lets TAA average the noise over frames. Volumetrics, SSR, SSAO, shadow filtering, and motion blur all do this. Dither noise that is not accumulated shows up as visible grain, so these effects are tuned together with the anti-aliasing mode.

### Early Exits

Return as soon as a pixel cannot contribute. Examples from the source:

- `if(depth <= 0.56) return;` skips the player hand in motion blur and depth of field.
- `deferred.glsl` returns for sky, hand, and pixels with no normal before running SSAO.
- `complexShadingDeferred` returns when `smoothness < 0.1`, before any reflection work.
- `rayTraceScene` returns when the ray points back toward the surface, leaves the screen, or hits the hand.
- `getShdMapping` returns zero when the surface faces away from the light and has no subsurface scattering.
- `fxaa.glsl` returns the center color when the local contrast is below the edge threshold, so only edge pixels pay for the search.

---

## Advanced Optimization Techniques

These techniques depend on how the GPU executes shaders: memory access, scheduling, and where work happens in the pipeline.

### Memory Bandwidth and Caching

On most scenes, fetching and writing buffers costs as much as the math. SDV reduces traffic in several ways:

- **Fewer and smaller writes.** Programs write only the targets they need. Simple programs write only `colortex4`; basic programs write `colortex4` and `colortex3`; only complex programs write all four of the scene, normal, albedo, and material targets. See the output sets in [BUFFERS.md](BUFFERS.md).
- **Reduced resolution.** Volumetrics (`composite1` to `composite3`) and bloom run at half resolution, and the history buffer is half resolution.
- **One buffer for many tiles.** Bloom packs five tiles of decreasing size into one half-resolution target. `composite8.glsl` fills the tiles from mip levels 1 to 5 of `colortex4`, and the blur passes return early for texels that are not inside any tile instead of blurring empty space.
- **Mips instead of more samples.** Depth of field and bloom read lower mip levels of `colortex4`, which are smaller and cache-friendly. The depth-of-field cost depends on the sample count (16), not on how large the blur is, because `currDofLOD` follows the circle of confusion.
- **Fewer fetches with linear sampling.** The bloom blur gets a 9-tap Gaussian from five fetches by placing taps between texels so the hardware filter does part of the averaging (technique from [rastergrid](https://www.rastergrid.com/blog/2010/09/efficient-gaussian-blur-with-linear-sampling/)). The offsets are computed in the vertex shader (`offSet0 = halfPixelWidth * 3.2307692308;` in `composite9.glsl`).
- **Coherent access.** Neighbor reads (TAA, SSAO blur, FXAA) fetch adjacent texels, which are likely already in cache from the neighboring pixel's fetch.
- **No clear when not needed.** See [Render Targets](#render-targets).

### Branchless Selection and Predictable Control Flow

Pixels in a GPU wave run in lockstep, so a branch that different pixels take differently makes the wave execute both sides. SDV prefers arithmetic selection in hot paths:

```glsl
// complexShadingForward.glsl: block light boost is 1.5 only for non-emissive materials
(1.0 + float(material.emissive == 0.0) * 0.5)
```

The voxel cloud traversal (`shaders/lib/rayTracing/voxelClouds.glsl`) chooses which axis to step on without branching:

```glsl
uvec2 stepAxis = uvec2(equal(nextDist, vec2(closestDist)));
closestDist = minOf(nextDist);

voxelPos += stepAxis * stepDir;
nextDist += stepAxis * stepSizes;
```

The screen-space ray tracer clips the ray to the screen once before marching so the loop needs no per-step bounds math for the clip:

```glsl
screenRayDir *= minOf((step(vec2(0), screenRayDir.xy) - screenPos.xy) / screenRayDir.xy);
```

Branches on values that are the same for every pixel of a draw, such as `isEyeInWater` or a `#if` macro, are cheap and not a divergence problem. Branches on per-pixel data, such as material properties, are only a problem when neighboring pixels disagree.

### Moving Work Earlier in the Pipeline

The cheapest pixel work is work not done per pixel:

- **Vertex shader instead of fragment shader.** Composite vertex shaders compute light, sky, and cloud colors and pass them as `flat` varyings, so they are evaluated per vertex (a screen quad has four) instead of per pixel (see `skyCol`, `lightCol`, and `cloudCol` in `composite.glsl` and `deferred1.glsl`). Terrain and entity programs pass the TBN matrix as `flat` because block faces are planar. `gbuffers_basic` and `gbuffers_particles` compute the shadow-space position per vertex and interpolate it. TAA jitter, curvature, and lightmap conversion also happen in the vertex stage.
- **CPU side instead of GPU side.** Per-frame values are computed in `shaders.properties` (see [Program Settings](#program-settings-in-shadersproperties)).
- **Interpolation modifiers.** `noperspective` on screen-space texture coordinates and `flat` on constant values avoid unneeded perspective correction and interpolation.
- **One big triangle.** `composite13.glsl` draws a 1×1 pass with a single oversized triangle generated from `gl_VertexID`, which avoids the diagonal seam of a two-triangle quad:

```glsl
gl_Position = vec4(vec2((gl_VertexID << 1) & 2, gl_VertexID & 2) * 2.0 - 1.0, 0, 1);
```

### Algorithms That Fit the GPU

SSR and voxel clouds are the pack's most heavily tuned effects, and both are built around how the hardware works:

- **Voxel clouds** use a DDA (digital differential analyzer) traversal. The ray is first intersected analytically with the cloud slab, so rays that miss it exit immediately. Inside the slab, the traversal visits each voxel exactly once and steps on the nearest voxel boundary, so cost follows the ray's length in voxels, not a fixed sample count or cloud density. Each voxel needs one `texelFetch` that returns both cloud channels, the 256-wide cloud map wraps with `& 255`, and the loop is capped at 100 iterations. Ray length is also clamped to the terrain distance. See `voxelClouds.glsl`.
- **SSR** clips the ray to the screen first, then marches a number of steps proportional to the ray's on-screen length, capped by `RAYTRACER_STEPS`. Binary refinement starts from the last depth sample and intersection result, saving one depth fetch, and the whole routine is skipped for surfaces that are not smooth enough to reflect. See `rayTracer.glsl`.

### VRAM

VRAM is mostly a function of render resolution, target formats, shadow-map resolution, and mip chains. The per-pixel table in [Render Targets](#render-targets) and the shadow-map figures in [Shadow Settings](#shadow-settings) give the scaling. Distant Horizons and Voxy add their own depth textures and geometry memory outside the pack's control.

### Precision and Packing

Format choices trade precision for bandwidth: `RGB8` for volumetric history, `R11F_G11F_B10F` for HDR color, and `RGB16_SNORM` for normals. Bit packing of buffer data is planned work (see [Open Optimization Work](#open-optimization-work)).

---

## Cost Map

This table describes what each effect scales with, based on the 1.3.9 source. It does not give timings. Fetch counts are per pixel for the pass and exclude the cost of any early exit.

| Effect | Program(s) | Resolution | What it scales with | Controlled by |
|---|---|---|---|---|
| Shadow maps | `shadow*` programs | Shadow map | Scene geometry within the shadow distance, and map resolution squared | `shadowMapResolution`, `shadowDistance`, entity toggles |
| Forward lighting | Complex gbuffers | Full | Shadow samples per pixel (1 with TAA, 2 without; 4 for subsurface materials), material complexity | `SHADOW_FILTER`, `SHADOW_COLOR`, `ANTI_ALIASING`, `SUBSURFACE_SCATTERING` |
| Parallax occlusion | Terrain, block, entity, hand | Full | Up to `PARALLAX_STEPS` height fetches, plus up to `PARALLAX_SHADOW_STEPS` for self-shadows | `PARALLAX_*` |
| SSAO | `deferred`, `deferred1` | Full | 4 depth fetches plus a 4-fetch blur | `SSAO` |
| SSR | `deferred1`, `composite` | Full | Up to `RAYTRACER_STEPS` depth fetches plus `RAYTRACER_BISTEPS` refinements, only where smoothness is at least `0.1` | `SSR`, `RAYTRACER_*` |
| SSGI | `deferred1`, `composite` | Full | Same ray tracer, run for every non-sky pixel | `SSGI`, `RAYTRACER_*` |
| Reflection history | `deferred1`, `composite` | Full | One extra fetch and a reprojection per reflection | `PREVIOUS_FRAME` |
| Volumetric lighting | `composite1` to `composite3` | Half | Up to 8 shadow samples per half-resolution pixel (fewer for short rays), plus a 7-fetch temporal pass and a 1-fetch upsample | `VOLUMETRIC_LIGHTING`, strength |
| Voxel clouds | `composite` | Full | DDA iterations (up to 100 per layer) bounded by the ray's length through the cloud slab, doubled by the second layer | `CLOUD_TYPE`, `DOUBLE_LAYERED_CLOUDS`, `CLOUD_THICKNESS` |
| Fog and sky | `deferred1`, `composite` | Full | ALU only | Fog settings |
| TAA | `composite4` | Full | Current, four neighbors, one history, and a depth fetch, plus a reprojection | `ANTI_ALIASING` |
| FXAA | `composite5` | Full | Cheap except on edges, where the search loop runs up to 12 iterations | `ANTI_ALIASING` |
| Motion blur | `composite6` | Full | 5 color fetches | `MOTION_BLUR` |
| Depth of field | `composite7` | Full | 16 fetches at a mip level that follows the blur size | `DOF` |
| Bloom | `composite8` to `composite12` | Half | Tile downsample, two blurs of 5 fetches, 8 fetches per tile in the upsample (5 tiles), and an apply | `BLOOM` |
| Lens flare | `composite11` | Half | ALU, skipped when the flare is not visible | `LENS_FLARE` |
| Auto exposure | `composite13`, `composite14` | One texel | One mip fetch | `AUTO_EXPOSURE` |
| Tonemapping and grading | `composite14` | Full | ALU and 1 to 2 fetches | Tonemap settings |
| Outlines | `deferred1` | Full | 4 depth fetches | `OUTLINES` |
| Water | `gbuffers_water`, `dh_water`, `voxy_translucent` | Full | Normal map from 3 noise evaluations (2 fetches each), a depth fetch for absorption and foam | `WATER_*` |
| Caustics | Shadow programs | Shadow map | Cell noise per water shadow fragment | `UNDERWATER_CAUSTICS`, `SHADOW_COLOR` |
| LOD terrain | `dh_*`, `voxy_*` | Full | Simplified lighting with no shadow-map sampling | Distant Horizons and Voxy settings |

### Reading the Pipeline

- **Resolution.** Full-resolution passes scale with the pixel count; half-resolution passes cost a quarter as much; the shadow map scales independently of the screen.
- **Per-pixel conditionals.** SSR, SSGI, POM, and clouds do their work only on the pixels that need it, so their cost depends on the scene as well as the settings.
- **Bandwidth.** Passes with many neighbor reads (TAA, SSAO blur, bloom upsample, FXAA) are limited by fetches more than math. Passes like fog and tonemapping are ALU-bound.
- **Hidden multipliers.** Several effects need a companion: SSR with `PREVIOUS_FRAME` also pays the `composite4` history write, shadow filtering and dithered effects rely on TAA to look right, and volumetrics need the shadow map.

---

## Review Checklist

When changing shader code, compare the implementation before and after under the same scene and settings. Check that:

- texture samples or loop iterations were not added unintentionally;
- values that do not change per pixel or per iteration are computed outside the pixel or loop, in the vertex shader, or in `shaders.properties`;
- a feature remains behind its existing setting and `#if` condition, and its uniforms and samplers are only declared when it is enabled;
- producer and consumer buffer ordering remains valid (see [BUFFERS.md](BUFFERS.md));
- reduced-resolution passes use the half-resolution uniforms and coordinates;
- early exits are kept, and new per-pixel branches do not depend on data that varies between neighboring pixels;
- visual correctness is checked in each relevant dimension and integration.

---

## Open Optimization Work

Planned work recorded in [TODO.md](../TODO.md):

- Implement bit packing for buffer data.
- Optimize depth of field calculations with noise.
- Optimize block IDs in `block.properties` and day-and-night transition calculations.
- Refactor uniform usage and remove unnecessary ones.

---

## Measured Results

No measurements are recorded yet. Add captures here using the procedure above.

| Date | Hardware and driver | Resolution | Profile | Scene | Change | Frame time before | Frame time after |
|---|---|---|---|---|---|---|---|
| | | | | | | | |