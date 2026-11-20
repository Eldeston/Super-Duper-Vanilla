# Optimization Guide

This guide is for developers who contribute to or study the SDV codebase. It explains how to measure performance, which pipeline-level controls affect cost, which optimization techniques the source already uses, and how to recognize what makes an effect expensive. [CONTRIBUTION.md](../CONTRIBUTION.md) requires testing the shader before submitting a pull request, optimizing code wherever possible, and adding comments when necessary.

This guide contains no measured per-feature timings. Costs are described by what they scale with (resolution, loop iterations, texture fetches), because actual frame time depends on the GPU, driver, scene, resolution, and settings. For exact settings and profile definitions, see [SETTINGS.md](SETTINGS.md); for pass responsibilities, see [PROGRAMS.md](PROGRAMS.md); for buffer details, see [BUFFERS.md](BUFFERS.md).

## Contents

1. [Profiling](#profiling)
2. [Pipeline-Level Optimization](#pipeline-level-optimization)
3. [Optimization Techniques](#optimization-techniques)
4. [Cost Map](#cost-map)
5. [Contributor Checklist](#contributor-checklist)
6. [Recording Results](#recording-results)

---

## Profiling

For buffer debugging and execution-time profiling, use [GFX Debuggers](https://modrinth.com/mod/gfx-debuggers) alongside [NVIDIA Nsight Graphics](https://developer.nvidia.com/nsight-graphics) or [RenderDoc](https://renderdoc.org/). Treat each capture as specific to the tested hardware, driver, scene, resolution, and settings.

Measurement procedure:

1. Select a repeatable scene and keep view position, render resolution, render distance, weather, and time of day fixed.
2. Allow shader compilation and scene loading to finish before recording a baseline.
3. Use the same measurement method for every comparison.
4. Change one setting or one piece of code at a time, then repeat the same capture.
5. Record the changed setting, scene, resolution, profile, hardware, and observed result together.

Frame time and FPS are related by the captured frame rate, but averages can hide stutter; compare consistent capture windows. Do not treat an FPS target or timing from another system as a measurement of your own setup.

When reading a capture, check four things for each pass: its resolution (see the [resolution table](#pass-resolution)), how many texture fetches it performs per pixel, how many loop iterations it runs, and which buffers it reads and writes.

---

## Pipeline-Level Optimization

Many costs are decided before any shader code runs: buffer formats and sizes, which programs are enabled, and which fixed-function work (blending, alpha testing, culling) the pipeline performs. These are configured through Iris settings in `shaders.properties` and constants in `final.glsl`.

### Buffers

Formats are declared in the comment block of [`final.glsl`](../shaders/main/final.glsl), which Iris reads, and sizes are set in [`shaders.properties`](../shaders/shaders.properties):

```
size.buffer.colortex0 = 0.5 0.5
size.buffer.colortex6 = 0.5 0.5
size.buffer.colortex7 = 1 1
```

| Target | Format | Nominal bytes per pixel | Size |
|---|---|---:|---|
| `colortex0` | `R11F_G11F_B10F` | 4 | Half × half |
| `colortex1` | `RGB16_SNORM` | 6 | Full |
| `colortex2` | `RGBA8` | 4 | Full |
| `colortex3` | `RGB8` | 3 | Full |
| `colortex4` | `R11F_G11F_B10F` | 4 | Full |
| `colortex5` | `R11F_G11F_B10F` | 4 | Full |
| `colortex6` | `RGB8` | 3 | Half × half |
| `colortex7` | `R16F` | 2 | 1 × 1 |

Guidelines drawn from these choices:

- **Use the smallest sufficient format.** The HDR scene and previous-frame buffers use `R11F_G11F_B10F` (32 bits per pixel) instead of a 64-bit `RGBA16F`. Material and mask data fit in `RGB8`.
- **Use reduced-resolution targets for expensive, low-frequency work.** Volumetrics, volumetric history, and bloom run at a quarter of the pixels.
- **Reuse buffers.** Iris is limited to 16 render targets, so lanes are intentionally multipurposed. `colortex0` carries volumetrics and then bloom; `colortex3` carries material data and then final color. Before reusing a lane, confirm that no later pass still needs the old contents.
- **Do not clear what you overwrite.** Clearing costs bandwidth, so buffers that are always fully rewritten or hold history are not cleared:

```glsl
// Disable to save performance
const bool shadowcolor0Clear = false;
const bool colortex0Clear = false;
const bool colortex2Clear = false;
```

`colortex5`, `colortex6`, and `colortex7` are also not cleared because they hold history. `colortex1` and `colortex4` keep their clears to prevent artifacts; do not disable the clears of the main HDR scene and normals.

- **Enable mipmaps only where a pass samples them.** A buffer must be declared mipmapped by force before `textureLod` can use its mip levels (`colortex4MipmapEnabled` in `composite7` and `composite8`). Mip generation has a cost, so do not declare it for buffers that do not need it.

**Nominal VRAM.** Per full-resolution pixel the color targets total about 22.75 bytes: `6 + 4 + 3 + 4 + 4` for the five full-size targets, plus `(4 + 3) × 0.25` for the two half-size targets. At 1920 × 1080 that is roughly 45 MiB. This excludes depth textures, the mip chain on `colortex4`, driver padding of three-channel formats, and shadow maps, so treat it as a lower bound. Resolution scales every full-size target; render scale changes therefore have a large effect.

### Quality Settings That Change Workload

| Setting | Effect on workload |
|---|---|
| `shadowMapResolution` (`512`–`8192`) | Shadow-map pixel count scales with the square of the resolution, affecting fill rate and VRAM for each shadow attachment (`shadowtex0`, plus `shadowtex1` and `shadowcolor0` with colored shadows) |
| `shadowDistance` (`32`–`1024`) | Sets how much geometry is drawn into the shadow pass and the texel density; larger distances spread the same resolution further |
| `SHADOW_COLOR` | Adds writes to `shadowcolor0`, an extra `shadowtex1` attachment, and extra fetches when sampling translucent shadows |
| `UNDERWATER_CAUSTICS` | Adds noise evaluation in the water shadow fragment shaders; requires `SHADOW_COLOR` |
| `SHADOW_FILTER` | Adds shadow samples per shaded fragment (see [shadow sampling](#cost-map)) |
| `ENTITY_SHADOWS`, `BLOCK_ENTITY_SHADOWS` | Control whether entities and block entities are drawn into the shadow map; entity shadows use half the shadow distance (`entityShadowDistanceMul = 0.5`) |
| `RAYTRACER_STEPS`, `RAYTRACER_BISTEPS` | Upper bound on the iterations of SSR and SSGI ray marching and refinement |
| `PREVIOUS_FRAME` | Keeps `composite4` running for SSR and SSGI history |
| `ANTI_ALIASING` | Selects which of `composite4` and `composite5` run, and whether projection jitter is applied |
| `VOLUMETRIC_LIGHTING`, `SHADOW_MAPPING` | Decide whether the volumetric ray march samples the shadow map and whether `composite2` runs |
| `CLOUD_TYPE`, `DOUBLE_LAYERED_CLOUDS` | Voxel clouds are traced at full resolution, once per layer |
| `PARALLAX_STEPS`, `PARALLAX_SHADOW_STEPS` | Upper bound on parallax occlusion loop iterations (LabPBR only) |
| `NORMAL_GENERATION` | Adds extra albedo fetches per fragment |
| `BLOOM`, `DOF`, `MOTION_BLUR` | Enable `composite8`–`composite12`, `composite7`, and `composite6` respectively |

### Pack Properties

These settings in `shaders.properties` remove fixed-function and CPU-side work:

| Property | Effect |
|---|---|
| `shadow.culling`, `frustum.culling`, `occlusion.culling` | Cull geometry that cannot contribute (occlusion culling is Iris only) |
| `blend.*` | Blending is turned off for most programs so the output is written directly; only additive and translucent programs blend |
| `blend.<program>.colortex1`/`2`/`3` | Blending is disabled per buffer on translucent programs, so normals, albedo, and material data are written directly instead of being blended |
| `alphaTest.*` | Alpha testing is disabled for all programs; programs test `ALPHA_THRESHOLD` manually and `discard` |
| `rain.depth = false` | Rain does not write depth |
| `sky`, `stars` = `false`, `sun`, `moon` | Vanilla sky geometry is not rendered unless the vanilla sun and moon are selected |
| `dhClouds = off`, `dhShadow.enabled = false` | Distant Horizons clouds and shadows are not rendered |
| `shadowBlockEntities`, `shadowEntities` | Set to `false` when the corresponding setting is off |

The per-buffer blending lines look like this:

```
blend.gbuffers_water.colortex1 = off
blend.gbuffers_water.colortex2 = off
blend.gbuffers_water.colortex3 = off
```

### Enabling and Disabling Programs

Composite programs that a feature does not need are disabled outright in `shaders.properties`. The conditions repeat for every dimension folder:

```
#if !defined VOLUMETRIC_LIGHTING || !defined SHADOW_MAPPING
    program.world-4/composite2.enabled = false
    ...
    program.world1/composite2.enabled = false
#endif

program.world0/composite6.enabled = MOTION_BLUR
```

The full list of conditions is in [PROGRAMS.md](PROGRAMS.md#composite-programs). A disabled composite costs nothing, including its buffer reads and writes. Prefer this over an early `return` inside the shader whenever a whole pass can be skipped.

**Gbuffers programs cannot be disabled this way.** There is no `program.*.enabled` entry for any gbuffers program. Disabling one makes Iris fall back to the vanilla program, which does not write the pack's buffers and corrupts whatever the later passes expect in them. Deferred programs are likewise always enabled.

Instead, programs that must exist but do not need to do work are disabled in code, so they produce no fragments. The vertex shader moves the geometry off screen and the fragment shader discards:

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

Programs that do this: `shadow_lightning` and `gbuffers_skybasic` (always), the shadow programs when `SHADOW_MAPPING` or `WORLD_LIGHT` is off, `gbuffers_clouds` unless `CLOUD_TYPE` is `0`, and `gbuffers_weather` when `FORCE_DISABLE_WEATHER` is set.

**Compile only what a dimension needs.** Each dimension folder defines its own flags in `world.glsl`. `FORCE_DISABLE_CLOUDS`, `FORCE_DISABLE_WEATHER`, `FORCE_DISABLE_DAY_CYCLE`, and an undefined `WORLD_LIGHT` compile whole code paths (shadows, clouds, weather, day-cycle uniforms, volumetrics) out of that dimension's programs. Composite vertex shaders also declare varyings and uniforms only when the feature that reads them is enabled.

---

## Optimization Techniques

### Everyday ALU Savings

These are micro-optimizations; apply them by habit, but do not expect large gains from any one of them. The shared helpers live in [`common.glsl`](../shaders/lib/utility/common.glsl).

- **Multiply instead of `pow` for small integer powers.** Use the `squared` and `cubed` helpers rather than `pow(x, 2.0)`.
- **Use `inversesqrt` for normalization and `lengthSquared` for comparisons.**

```glsl
float squared(in float x){ return x * x; }

vec3 fastNormalize(in vec3 x){ return x * inversesqrt(lengthSquared(x)); }
```

- **Replace `pow` with a polynomial when the range is known.** The sRGB conversions use a polynomial fit instead of `pow(x, 2.2)`; the original `pow` versions remain in a comment for reference.

```glsl
vec3 toLinear(in vec3 x){ return ((2.10545 + x) * (0.0231872 + x)) * x * 0.315206; }
```

- **Multiply by a reciprocal instead of dividing**, and precompute constants at compile time. Constants derived from macros are `const`, so the compiler folds them:

```glsl
const vec3 exposureTint = vec3(TINT_R, TINT_G, TINT_B) * (EXPOSURE * 0.00392156863);
```

`settings.glsl` ends with a block of precalculated constants (for example `cloudDepthInverse = 1.0 / CLOUD_THICKNESS`) for the same reason.

- **Use cheap approximations in a known range.** `fastSqrt(x)` is `x * (2.0 - x)` for values in `0`–`1`, and `smoothen` is the cubic smoothstep without the clamp.
- **Wrap power-of-two lookups with a bit mask.** The 256 × 256 noise texture is indexed with `& 255` instead of `fract` or `mod`.

### Sampling Techniques

- **Use `texelFetch` when no filtering, wrapping, or mip selection is needed.** It skips the sampler and coordinate math. Most composite passes read their inputs this way, for example the scene color read at the top of every composite:

```glsl
sceneColOut = texelFetch(colortex4, screenTexelCoord, 0).rgb;
```

- **Use `textureLod(..., 0)` instead of `texture` when mips are not needed**, which avoids the implicit derivative calculation for level-of-detail. Alpha-tested programs sample `gtexture` this way.
- **Hoist derivatives.** `integratedPBR.glsl` and `labPBR.glsl` compute `dFdx(texCoord)` and `dFdy(texCoord)` once and pass them to every `textureGrad` call.
- **Let the hardware filter for you.** The 9 × 9 Gaussian blur uses linear sampling to cover nine taps with five fetches:

```glsl
// Optimized 9x9 gaussian blur with only 5 texture fetches
// Technique from https://www.rastergrid.com/blog/2010/09/efficient-gaussian-blur-with-linear-sampling/
vec3 sample0 = textureLod(colortex0, vec2(texCoord.x - offSet0, texCoord.y), 0).rgb +
    textureLod(colortex0, vec2(texCoord.x + offSet0, texCoord.y), 0).rgb;
vec3 sample1 = textureLod(colortex0, vec2(texCoord.x - offSet1, texCoord.y), 0).rgb +
    textureLod(colortex0, vec2(texCoord.x + offSet1, texCoord.y), 0).rgb;
vec3 center = textureLod(colortex0, texCoord, 0).rgb;

bloomColOut = sample0 * 0.0702702703 + sample1 * 0.3162162162 + center * 0.2270270270;
```

- **Use mip levels as a free blur.** Bloom tiles and depth of field read `colortex4` at a mip level chosen from the required blur size instead of summing many full-resolution taps.
- **Reuse samples you already have.** The binary refinement of the ray tracer reuses the depth and intersection from the last march step, saving a fetch:

```glsl
// Reuse stored sampled depth and intersection to use 1 less depth sample
for(uint i = 1u; i <= rayTraceBiSteps; i++){
    // Refine ray direction
    screenRayDir *= 0.5;
    screenRayPos += intersection ? -screenRayDir : screenRayDir;

    // Return early if we're on the last iteration
    if(i == rayTraceBiSteps) return screenRayPos.xy;
```

- **Get several random values from one texture fetch pattern.** One noise texture provides decorrelated values by mirroring the coordinates:

```glsl
vec2 getRng2(in ivec2 iuv){
    return vec2(texelFetch(noisetex, iuv, 0).x, texelFetch(noisetex, ivec2(255 - iuv.x, iuv.y), 0).x);
}
```

### Loops and Early Exits

- **Calculate as much as possible outside the loop.** The volumetric ray march computes its step vector and start position once, so the loop body is a single shadow sample and an add:

```glsl
for(uint i = 0u; i < dynamicVolumetricLightSteps; i++){
    // No need to do anymore fancy matrix multiplications during the loop
    volumeData += getShdCol(getShdDistort(startPos));
    // We continue tracing!
    startPos += endPos;
}
```

SSAO builds its four sample offsets from one noise read with swizzles instead of iterating a fractional offset:

```glsl
// Instead of iterating by adding stepSize and using fract every time, we swizzle + one fract instead for pleasant and optimized results
vec3 baseDither = dither.xyz * 0.5 - 0.25;
vec3 ditherSwizzle[4] = vec3[4](
    baseDither.xyz,
    baseDither.zxy,
    baseDither.yzx,
    fract(dither.zyx + GOLDEN_RATIO) * 0.5 - 0.25
);
```

- **Use fixed, small loop counts and unsigned counters.** Loops use `uint` counters with a bound that is a constant or a small derived value, and loops that cannot be bounded by a constant carry a hard cap (the voxel cloud trace stops at 100 iterations).
- **Exit early for pixels that cannot contribute.** Examples in the source:

```glsl
// Return immediately if player hand
if(depth <= 0.56) return;
```

SSAO skips the sky, the hand, and pixels with no normal. The ray tracer returns before marching if the reflection ray points toward the surface, leaves the screen, or reaches the sky. Shadow mapping returns immediately for fragments that face away from the light and are not subsurface:

```glsl
if(!isShadow && !isSubSurface) return vec3(0);
```

- **Spend fewer samples where temporal filtering covers the noise.** Shadow filtering uses one sample when TAA is on and two when it is off:

```glsl
#if ANTI_ALIASING >= 2
    return getShdCol(shdPos, dither, shadowMapPixelSize, 1u) * (shdFactor * NLZ);
#else
    return getShdCol(shdPos, dither, shadowMapPixelSize, 2u) * (shdFactor * NLZ);
#endif
```

### Memory Bandwidth and Caching

Texture fetches and buffer traffic are often the limiting factor, especially on integrated and mobile GPUs. Confirm with a profiler before optimizing.

- **Touch fewer pixels.** Half-resolution buffers, one-texel buffers, and early exits all reduce the number of pixels read and written. Upsampling from a half-resolution buffer is a single nearest fetch:

```glsl
sceneColOut += texelFetch(colortex0, ivec2(gl_FragCoord.xy * 0.5), 0).rgb * lightCol * volumetricFogDensity;
```

- **Keep per-pixel data compact.** Normals, albedo and SSAO, and material and mask share small formats; the TODO list tracks bit packing as a further reduction.
- **Pack several results into one buffer.** Bloom stores five blur tiles of different sizes in one half-resolution buffer, so the blur passes touch one buffer instead of five. The blur passes also skip tiles that fall in empty space:

```glsl
// Skip empty spaces
if(
    isBloomTile(vec3(0), texCoord, 2, 1) &&
    isBloomTile(bloomColOut, vec2(texCoord.x, texCoord.y - 0.5078125), 4, 2) &&
    ...
```

- **Keep lookup textures small and local.** The noise and cloud map are effectively 256 × 256 (indexed with `& 255`), and neighbor reads (TAA, FXAA, outlines, SSAO blur) touch adjacent texels, which keeps them in cache.
- **Pick the right shadow sampler.** Forward-shaded programs use a hardware-compared `sampler2DShadow` (`shadowHardwareFiltering = true`, so bilinear comparison is free). The volumetric pass fetches raw shadow depth with `texelFetch` and compares manually (`shdSampleTexel.glsl`), because it needs point samples.
- **Do not sample a buffer you are writing in the same pass.** The pipeline relies on Iris ping-ponging buffers between passes; keep read and write roles clear.

### Branchless Code and Divergence

Neighboring pixels run together, so a branch only costs extra when they disagree. Branch on values that are uniform across a primitive (flat varyings, uniforms, compile-time macros) and use arithmetic selects for per-pixel data.

- **Compile-time `#if` for settings; arithmetic for per-pixel data.** For example, the block light multiplier uses a comparison cast to float instead of a branch:

```glsl
(1.0 + float(material.emissive == 0.0) * 0.5)
```

- **Replace comparisons that select an axis or a side with `step`, `equal`, `min`, `max`, and `mix`.** The voxel cloud DDA picks the stepping axis without a branch:

```glsl
// Calculate the step's axis first, also fixes backface rendering
uvec2 stepAxis = uvec2(equal(nextDist, vec2(closestDist)));
// Find the closest voxel distance
closestDist = minOf(nextDist);

// Continue voxel tracing!
voxelPos += stepAxis * stepDir;
nextDist += stepAxis * stepSizes;
```

- **Material tables branch on `flat` block IDs.** In `integratedPBR.glsl` the long `if`/`else if` chain on `id` branches on a value that is constant across a primitive, so it is coherent. Keep it that way: do not branch on per-pixel texture data to choose between whole code paths when you can compute both cheaply and select.

### Moving Work to the Vertex Stage

Anything that does not vary per pixel should be computed per vertex or per primitive and passed as a `flat` varying. Fullscreen passes have only a few vertices, so work done in their vertex shaders is effectively free:

```glsl
flat out vec3 skyCol;

noperspective out vec2 texCoord;
...
skyCol = toLinear(SKY_COLOR_DATA_BLOCK);
```

Examples in the source:
- Composite vertex shaders compute light, sky, sun, moon, and cloud colors and the cloud start position once per frame (`composite.glsl`, `deferred1.glsl`).
- The Gaussian blur offsets and the depth-of-field scale are computed in the vertex shader (`composite9.glsl`, `composite10.glsl`, `composite7.glsl`):

```glsl
offSet0 = halfPixelWidth * 3.2307692308;
offSet1 = halfPixelWidth * 1.3846153846;
```

- The lens flare position and visibility are computed in the vertex shader (`composite11.glsl`).
- Programs with basic shading compute the shadow-space position per vertex (`vertexShdPos` in `gbuffers_basic` and `gbuffers_particles`), and terrain animation displaces vertices instead of per-pixel coordinates.
- `composite13` covers its single-texel target with one oversized triangle generated from `gl_VertexID`, so it needs no vertex buffer:

```glsl
gl_Position = vec4(vec2((gl_VertexID << 1) & 2, gl_VertexID & 2) * 2.0 - 1.0, 0, 1);
```

Use `noperspective` on fullscreen texture coordinates to skip perspective correction, and `flat` where interpolation is unnecessary.

Moving work to the vertex stage has limits: high-polygon meshes (terrain, entities) run the vertex shader many more times than a screen quad, so keep animation and transforms cheap.

### Doing Less Work Per Effect

- **Fake it where it is cheap.** With shadow mapping off, programs fall back to lightmap-based fake shadows; volumetrics fall back to a height-faded value; Distant Horizons and Voxy terrain use a lighting path with no shadow map (`complexShadingLOD.glsl`).
- **Prevent overdraw.** LOD programs discard fragments that real geometry already covers:

```glsl
// Prevents overdraw
if(far > vertexViewDist){ discard; return; }
```

- **Accumulate over time instead of sampling more.** Volumetrics, SSR and SSGI previous-frame color, and shadow filtering all lean on dithering with temporal accumulation, so each frame can use few samples.
- **Cap and scale iterations.** Volumetric steps and the SSR march scale with distance and ray length rather than always running the maximum.
- **Work around driver issues once.** `getDepth` includes a fix for a known AMD depth problem instead of scattering the check through every program.

---

## Cost Map

This section helps you recognize what makes an effect expensive from its implementation and where it sits in the pipeline. It describes what each effect scales with; it does not give timings.

### Pass Resolution

| Resolution | Passes |
|---|---|
| Shadow map (`shadowMapResolution`²) | All shadow programs |
| Full | Gbuffers, `deferred`, `deferred1`, `composite`, `composite3`–`composite7`, `composite12`, `composite14`, `final` |
| Half × half | `composite1`, `composite2`, `composite8`–`composite11` (they write the half-resolution `colortex0` and `colortex6`) |
| One texel | `composite13` |

### Cost by Effect

| Effect | Where | What it scales with |
|---|---|---|
| Gbuffers geometry | Gbuffers | Visible geometry, overdraw, and the work of the forward shading in each fragment; forward lighting runs for every shaded fragment, including ones later covered |
| Shadow sampling | Forward-shaded Gbuffers | One sample with TAA and two without per fragment, four for subsurface materials; skipped for fragments facing away from the light |
| Parallax occlusion | Terrain, entities, hand, blocks (LabPBR) | Up to `PARALLAX_STEPS` height fetches per fragment, plus `PARALLAX_SHADOW_STEPS` for self-shadows |
| Generated normals | Terrain, water, blocks | Three extra albedo fetches per fragment |
| Water surface | `gbuffers_water` | Water normals use three cell-noise evaluations of two fetches each, plus a `depthtex1` fetch for absorption and foam |
| SSAO | `deferred` | Four depth fetches per pixel, plus a four-fetch blur in `deferred1`; skipped for sky, hand, and pixels without normals |
| SSR and SSGI | `deferred1`, `composite` | SSR runs per pixel with smoothness of at least `0.1` (SSGI runs before that check, for every shaded pixel); the march runs `uint(rayLength)` iterations, where `rayLength` is the on-screen length of the ray (clipped to the screen) times `RAYTRACER_STEPS`, so short rays take fewer steps; refinement adds `RAYTRACER_BISTEPS`; one fetch of previous-frame color on a hit |
| Voxel clouds | `composite` (and sky reflections) | Number of voxels the ray crosses inside the cloud slab, capped at 100 iterations per layer; the slab is intersected analytically so rays that miss it exit immediately; each layer is a full pass of this work |
| Volumetric lighting | `composite1`–`composite3` | Up to eight shadow-map steps per half-resolution pixel (the equivalent of about two steps per full-resolution pixel), fewer for short rays; plus the temporal accumulation and one upsample fetch |
| TAA | `composite4` | One depth fetch, one history fetch, and five scene fetches per pixel |
| FXAA | `composite5` | Early out for low-contrast pixels; otherwise an edge search of up to 12 iterations |
| Motion blur | `composite6` | Four extra scene fetches per pixel; skipped for the hand |
| Depth of field | `composite7` | Sixteen taps at a mip level chosen from the blur radius, so the tap count stays constant |
| Bloom | `composite8`–`composite12` | Five tile fetches to build, five fetches per axis to blur, and eight fetches per tile (forty) to upsample, all at half resolution; empty tile areas are skipped |
| Lens flare | `composite11` | Arithmetic only, evaluated when the light source is visible |
| Auto exposure | `composite13`, `composite14` | One texel written, one mip fetch; one texel read per pixel in tonemapping |
| Tonemapping and grading | `composite14` | Arithmetic per pixel |
| Final filters | `final` | Chromatic aberration adds two extra fetches; sharpening adds four |
| Outlines | `deferred1` | Four depth fetches per pixel |
| Terrain, water, and weather animation | Vertex shaders | A few trigonometric functions per vertex |
| LOD terrain | Distant Horizons and Voxy programs | Overdraw rejection and a lighting path with no shadow map |

SSR and the voxel cloud trace are designed to be cheap by construction: both march with constant steps in a space where the GPU's strengths apply (screen-space depth fetches for SSR, a DDA over a small 256 × 256 cloud map for clouds), exit early at the first opportunity, and do no per-step lighting. The maintainer reports they run smoothly on mobile hardware; this has not been measured here.

### Reading the Cost of a Change

When you change a pass, ask these in order:

1. Does it run at full, half, or one-texel resolution?
2. Does it run for every pixel, or only for a subset (materials, depth, mask, ray length)?
3. How many fetches and loop iterations does it add per pixel, and are they bounded by a setting?
4. Does it read or write an additional buffer, or require a new mip chain?
5. Can part of it move to a vertex stage, a `const`, or an earlier pass?

---

## Contributor Checklist

When changing shader code, compare the implementation before and after under the same scene and settings. Check that:

- texture fetches or loop iterations were not added unintentionally, and any added loop has a bound;
- a feature remains behind its existing setting and program condition, and whole passes are disabled in `shaders.properties` when the feature is off;
- gbuffers programs still write every buffer the later passes expect (they cannot be disabled);
- producer and consumer buffer ordering remains valid (see [BUFFERS.md](BUFFERS.md)), and a reused lane is not read after being overwritten;
- reduced-resolution passes use the configured target dimensions;
- work that does not vary per pixel has been moved to the vertex stage or a `const`;
- visual correctness is checked in relevant dimensions and integrations (Distant Horizons, Voxy, and Physics Mod paths);
- code follows [CONTRIBUTION.md](../CONTRIBUTION.md) formatting rules, and comments explain any non-obvious optimization.

---

## Recording Results

Publish results only with enough context to reproduce them. For each measurement, record:

| Field | Example content |
|---|---|
| GPU and driver | Model and driver version |
| Resolution and render scale | Output resolution and `MC_RENDER_QUALITY` |
| Profile and changed settings | Profile name plus the single setting changed |
| Scene | Location, time of day, weather, dimension |
| Tool and method | GFX Debuggers with Nsight Graphics or RenderDoc, and which counter or timing was read |
| Result | Per-pass or per-frame time, with the baseline it was compared against |