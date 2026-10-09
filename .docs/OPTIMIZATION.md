# Optimization Guide

This guide describes how to measure and reason about SDV performance. It does not assign hardware-independent frame-time costs to individual features. For exact controls and profile definitions, see [SETTINGS.md](SETTINGS.md); for pass responsibilities, see [PROGRAMS.md](PROGRAMS.md).

## Workload Characteristics

| Workload | Relevant SDV settings/programs | Scaling factor |
|---|---|---|
| Shadow map | `shadowMapResolution`, `shadowDistance`; shadow programs | Shadow-map pixel count grows with the square of resolution |
| Geometry shading | Terrain, entity, block, water, and particle Gbuffers | Varies with visible geometry and material features |
| Screen-space effects | SSAO, SSR, SSGI, TAA, motion blur, DOF | Most run over screen pixels; their work also depends on sample/step counts |
| Volumetrics and bloom | `composite2`-`composite3`, `composite8`-`composite12` | `colortex0` is half width and half height, or one quarter of full-resolution pixel count |
| Ray tracing | `RAYTRACER_STEPS`, `RAYTRACER_BISTEPS` | More steps perform more ray/depth tests |

These are scaling relationships, not performance estimates. Actual results depend on GPU, driver, resolution, scene content, and selected settings.

## Measurement Procedure

1. Select a repeatable scene and keep view position, render resolution, render distance, weather, and time of day fixed.
2. Allow shader compilation and scene loading to finish before recording a baseline.
3. Record frame time using the available game overlay or GPU profiling tool; use the same measurement method for every comparison.
4. Change one setting or profile at a time, then repeat the same capture.
5. Record the changed setting, scene, resolution, profile, and observed frame time with the result.

Do not treat an FPS target or timing from another system as a measurement of your own setup. Frame time and FPS are related by the captured frame rate, but averages can hide stutter; compare consistent capture windows.

## Isolating a Workload

Use the shader menu options and profiles in [SETTINGS.md](SETTINGS.md) to isolate features. Examples of independent controls include `SHADOW_MAPPING`, `VOLUMETRIC_LIGHTING`, `SSAO`, `SSR`, `SSGI`, `BLOOM`, `DOF`, and `MOTION_BLUR`. For a pass-by-pass interpretation, consult the composite map in [PROGRAMS.md](PROGRAMS.md).

The `POTATO`, `LOW`, `MEDIUM`, `HIGH`, and `ULTRA` profiles are defined in `shaders/shaders.properties`; their exact inherited assignments are listed in [SETTINGS.md](SETTINGS.md). This guide does not duplicate those recipes.

## Interpreting Results

- If changing `shadowMapResolution` changes frame time, the shadow-map workload contributes to the measured scene. Increasing resolution increases shadow-map pixel count quadratically.
- If changing `RAYTRACER_STEPS` or `RAYTRACER_BISTEPS` changes frame time, screen-space ray traversal/refinement contributes to that workload.
- If view resolution changes frame time substantially, full-resolution Gbuffers or full-screen effects may be significant. The half-resolution volumetric/bloom target reduces the pixel count for those intermediates.
- If frame time varies between captures, check for changed scene content, shader compilation, background work, or different profiling conditions before attributing the change to a setting.

## Common Visual Symptoms

| Symptom | Settings or implementation to inspect |
|---|---|
| TAA ghosting or trails | `ANTI_ALIASING`, `PREVIOUS_FRAME`, and temporal reprojection in `shaders/main/composite4.glsl` |
| Noisy indirect lighting | SSGI is experimental; inspect the reflection/indirect-light path and the selected AA mode |
| Excessive bloom | `BLOOM_STRENGTH` and bloom composition in `composite8`-`composite12` |
| Hard or aliased shadows | `shadowMapResolution`, `shadowDistance`, and shadow filtering in `shdSampleVar.glsl` and the shadow sampling helpers |
| Fog differs between dimensions | Per-world fog settings and flags in `shaders/world-X/world.glsl` |

## Shader-Code Review Checklist

When changing shader code, compare the implementation before and after under the same scene and settings. Check that:

- texture samples or loop iterations were not added unintentionally;
- a feature remains behind its existing setting and program condition;
- producer/consumer buffer ordering remains valid (see [BUFFERS.md](BUFFERS.md));
- reduced-resolution passes use the configured target dimensions;
- visual correctness is checked in relevant dimensions and integrations.
