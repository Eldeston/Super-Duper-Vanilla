# Dimension Configuration

**Scope**: How each dimension is configured, every per-dimension option, its range, and its default  
**Related Docs**: [SETTINGS.md](SETTINGS.md) | [ARCHITECTURE.md](ARCHITECTURE.md) | [PROGRAMS.md](PROGRAMS.md) | [FEATURES.md](FEATURES.md)

---

## Table of Contents

1. [Overview](#overview)
2. [Dimension Mapping](#dimension-mapping)
3. [Configuration Layers](#configuration-layers)
4. [Option Reference](#option-reference)
5. [Default Values](#default-values)
6. [Color Pipeline](#color-pipeline)
7. [Vanilla Fog Color](#vanilla-fog-color)
8. [Rules for Consumers](#rules-for-consumers)
9. [Adding a Dimension](#adding-a-dimension)
10. [Portability Note](#portability-note)

---

## Overview

Every dimension is configured by its own `world.glsl` and exposes the same 59 options, for 413 in total across seven dimensions. The options appear in the shader menu (see [SETTINGS.md](SETTINGS.md#configuration)) and are resolved at compile time, so an option a dimension does not use costs nothing at runtime.

Code outside `world.glsl` never reads a prefixed option such as `WORLD0_SKY_CR`. It reads the resolved name, `WORLD_SKY_CR`, which always refers to the dimension currently being compiled.

---

## Dimension Mapping

`shaders/dimension.properties` maps dimension IDs to folders. Each folder holds thin `.vsh`/`.fsh` wrappers and one `world.glsl`.

| Folder | Dimensions | Option prefix | Menu screen |
|---|---|---|---|
| `world0` | `minecraft:overworld` | `WORLD0_` | Overworld |
| `world-1` | `minecraft:the_nether`, `minecraft:nether`, `undergarden:undergarden` | `WORLDn1_` | Nether |
| `world1` | `minecraft:the_end`, `minecraft:end` | `WORLD1_` | End |
| `world-2` | `dimdoors:public_pockets`, `dimdoors:dungeon_pockets` | `WORLDn2_` | Dimdoors: Pockets |
| `world-3` | `dimdoors:limbo` | `WORLDn3_` | Dimdoors: Limbo |
| `world-4` | `dimdoors:personal_pockets` | `WORLDn4_` | Dimdoors: Personal pockets |
| `world999` | `*` (any dimension not listed above) | `WORLD999_` | Wildcard dimension |

The prefix uses `n` in place of the minus sign because `-` is not valid in an identifier.

Each wrapper includes, in order: `/lib/settings.glsl`, `/lib/utility/common.glsl`, the local `world.glsl`, then `/main/<program>.glsl`.

---

## Configuration Layers

| Layer | File | Role |
|---|---|---|
| Values | `shaders/world-X/world.glsl` | Defines `WORLD_ID`, `WORLD_PREFIX`, and every prefixed option with its menu range |
| Resolver | `shaders/lib/dimension/worldResolver.glsl` | Maps each `WORLD_<NAME>` to `<PREFIX>_<NAME>` |
| Adapters | `shaders/lib/dimension/{sky,light,fog,star}Adapter.glsl` | Turn the options into colors and densities, including day cycle blending |
| Consumers | `shaders/main/`, `shaders/lib/` | Call the adapters or test the resolved flags |

`WORLD_ID` and `WORLD_PREFIX` are the only source-level identifiers that do not appear in the menu.

### Resolver

The resolver pastes the prefix and the suffix together with `##`:

```glsl
#define _WORLD_CONCAT(prefix, suffix) prefix##suffix
#define WORLD_CONCAT(prefix, suffix) _WORLD_CONCAT(prefix, suffix)
#define W_SYM(suffix) WORLD_CONCAT(WORLD_PREFIX, suffix)

#define WORLD_SKYBOX W_SYM(_SKYBOX)
```

The two-level `WORLD_CONCAT` is required so that `WORLD_PREFIX` is expanded before it is pasted.

### Adapters

| Adapter | Functions | Returns |
|---|---|---|
| `skyAdapter.glsl` | `worldSkyColor()` | Linear sky color, with the vanilla fog color applied |
| `lightAdapter.glsl` | `worldLightColor()`, `worldSunLight()` | Linear directional light color |
| `fogAdapter.glsl` | `worldFogTotalDensity()`, `worldFogVerticalDensity()` | Fog densities |
| `starAdapter.glsl` | `worldStarIntensity()` | Star intensity |

With `WORLD_DAYCYCLE == 1`, each adapter blends the Night, Twilight, and Day values over `dayCycle` (0 to 2). With `WORLD_DAYCYCLE == 0`, it returns the Constant value.

---

## Option Reference

Suffix convention: **C** = constant (used when the day cycle is off), **D** = day, **N** = night, **T** = twilight.

### Features

Each is `0` (Off) or `1` (On), and is tested with `#if WORLD_X == 1`.

| Option | Controls |
|---|---|
| `SKYBOX` | Textured skybox pass (`skytextured`) |
| `CLOUDS` | Clouds. Also requires `CLOUD_TYPE != 0` |
| `WEATHER` | Weather-dependent rendering. Declares `rainStrength` |
| `DAYCYCLE` | Day, night, and twilight blending. Declares `dayCycle`, `twilightPhase`, and `dayCycleAdjust` |
| `SKYLIGHT` | `1`: real skylight from the lightmap. `0`: the fixed `SKYLIGHT_I` amount |
| `LIGHT` | Directional sun or moon light: shadows, direct lighting, lens flare |
| `STARS` | Star field |
| `AETHER` | Aether sky layer (in `skyRender.glsl`) |
| `SKYGROUND` | Ground color below the horizon |
| `VANILLAFOG` | Use the vanilla fog color for the sky. Declares `fogColor` |

`SKYLIGHT` has inverted-looking polarity on purpose: `1` means real skylight, and only the Overworld sets it to `1`. Dimensions with `0` use `SKYLIGHT_I` as a constant.

### Basic

| Option | Values | Notes |
|---|---|---|
| `SKYLIGHT_I` | `0.00` to `1.00`, step `0.05` | Used when `SKYLIGHT` is `0` |
| `CELESTIAL` | `0` None, `1` Sun/Moon, `2` Black hole | Selects the celestial body drawn in the sky and the lens flare |
| `CELESTIAL_SIZE` | `0.00` to `0.50`, step `0.05` | Size of the celestial body |
| `VANILLAFOG_MODE` | `0` Replace, `1` Blend, `2` Multiply | See [Vanilla Fog Color](#vanilla-fog-color) |
| `VANILLAFOG_STRENGTH` | `0.00` to `1.00`, step `0.05` | Used by modes `1` and `2`, ignored by mode `0` |

### Stars

| Option | Values |
|---|---|
| `STAR_CI`, `STAR_DI`, `STAR_NI`, `STAR_TI` | `0.0` to `4.0` in steps of `0.5`, then `6.0` to `16.0` in steps of `2.0` |

### Light and Sky Colors

Twelve light options and twelve sky options per dimension.

| Pattern | Values |
|---|---|
| `LIGHT_{C,D,N,T}{R,G,B}` | `3` to `255`, step `3` |
| `SKY_{C,D,N,T}{R,G,B}` | `3` to `255`, step `3` |
| `LIGHT_{C,D,N,T}I` | `0.00` to `2.00`, step `0.05` |
| `SKY_{C,D,N,T}I` | `0.00` to `2.00`, step `0.05` |

The menu list starts at `3`, so it has no `0` entry. Several dimensions default to `0` (black), which is valid in the file but is outside the slider's list.

### Fog

| Pattern | Values |
|---|---|
| `FOG_TOTAL_{C,D,N,T}I` | `0.005` to `0.500`, step `0.010` |
| `FOG_VERTICAL_{C,D,N,T}I` | `0.005` to `0.500`, step `0.010` |

`world-4` additionally allows `0.000`, because it disables fog entirely.

### Option Count

| Group | Options |
|---|---|
| Features | 10 |
| Basic | 5 |
| Stars | 4 |
| Light | 16 |
| Sky | 16 |
| Fog | 8 |
| **Total per dimension** | **59** |

Seven dimensions give 413 options.

---

## Default Values

### Features

| Option | `0` Overworld | `-1` Nether | `1` End | `-2` Pockets | `-3` Limbo | `-4` Personal | `999` Wildcard |
|---|---|---|---|---|---|---|---|
| `SKYBOX` | 1 | 0 | 0 | 0 | 1 | 0 | 1 |
| `CLOUDS` | 1 | 0 | 0 | 0 | 0 | 0 | 1 |
| `WEATHER` | 1 | 0 | 0 | 0 | 0 | 0 | 1 |
| `DAYCYCLE` | 1 | 0 | 0 | 0 | 0 | 0 | 1 |
| `SKYLIGHT` | 1 | 0 | 0 | 0 | 0 | 0 | 1 |
| `LIGHT` | 1 | 0 | 1 | 0 | 0 | 0 | 1 |
| `STARS` | 1 | 0 | 1 | 0 | 0 | 0 | 1 |
| `AETHER` | 0 | 0 | 1 | 0 | 0 | 0 | 0 |
| `SKYGROUND` | 1 | 0 | 1 | 0 | 0 | 0 | 1 |
| `VANILLAFOG` | 0 | 1 | 0 | 0 | 1 | 1 | 0 |

### Basic

| Option | `0` | `-1` | `1` | `-2` | `-3` | `-4` | `999` |
|---|---|---|---|---|---|---|---|
| `SKYLIGHT_I` | 1.00 | 1.00 | 1.00 | 0.00 | 1.00 | 0.00 | 1.00 |
| `CELESTIAL` | 1 | 0 | 2 | 0 | 0 | 0 | 1 |
| `CELESTIAL_SIZE` | 0.10 | 0.00 | 0.25 | 0.00 | 0.00 | 0.00 | 0.10 |
| `VANILLAFOG_MODE` | 0 | 1 | 0 | 0 | 0 | 0 | 0 |
| `VANILLAFOG_STRENGTH` | 1.00 | 1.00 | 1.00 | 1.00 | 1.00 | 1.00 | 1.00 |

### Stars

| Option | `0` | `-1` | `1` | `-2` | `-3` | `-4` | `999` |
|---|---|---|---|---|---|---|---|
| `STAR_CI` | 4.0 | 4.0 | 16.0 | 4.0 | 4.0 | 4.0 | 4.0 |
| `STAR_DI` | 0.0 | 1.0 | 16.0 | 0.0 | 0.0 | 0.0 | 2.0 |
| `STAR_NI` | 4.0 | 1.0 | 16.0 | 0.0 | 0.0 | 0.0 | 4.0 |
| `STAR_TI` | 2.0 | 1.0 | 16.0 | 0.0 | 0.0 | 0.0 | 3.0 |

Star values of a dimension with `STARS` set to `0` have no effect.

### Light Color

Written as `R, G, B @ intensity`.

| Time | `0` Overworld | `1` End | `999` Wildcard |
|---|---|---|---|
| Constant | 255, 210, 165 @ 1.40 | 210, 165, 255 @ 1.00 | 255, 210, 165 @ 1.40 |
| Day | 255, 210, 165 @ 1.40 | 210, 165, 255 @ 1.00 | 255, 210, 165 @ 1.40 |
| Night | 45, 105, 150 @ 1.00 | 210, 165, 255 @ 1.00 | 45, 105, 150 @ 1.00 |
| Twilight | 255, 180, 75 @ 1.40 | 210, 165, 255 @ 1.00 | 255, 180, 75 @ 1.40 |

`-1`, `-2`, `-3`, and `-4` all use `3, 3, 3 @ 0.00` for every time, because `LIGHT` is off in those dimensions.

### Sky Color

| Time | `0` Overworld | `-1` Nether | `1` End | `999` Wildcard |
|---|---|---|---|---|
| Constant | 45, 105, 165 @ 1.40 | 39, 3, 78 @ 1.00 | 15, 3, 60 @ 1.00 | 45, 105, 165 @ 1.40 |
| Day | 45, 105, 165 @ 1.40 | 39, 3, 78 @ 1.00 | 15, 3, 60 @ 1.00 | 45, 105, 165 @ 1.40 |
| Night | 3, 30, 120 @ 1.00 | 39, 3, 78 @ 1.00 | 15, 3, 60 @ 1.00 | 3, 30, 120 @ 1.00 |
| Twilight | 60, 30, 120 @ 1.00 | 39, 3, 78 @ 1.00 | 15, 3, 60 @ 1.00 | 60, 30, 120 @ 1.00 |

`-2`, `-3`, and `-4` use `0, 0, 0 @ 1.00` for every time (black sky). In `-3` and `-4` the vanilla fog color provides the visible sky color.

### Fog Density

| Option | `0` | `-1` | `1` | `-2` | `-3` | `-4` | `999` |
|---|---|---|---|---|---|---|---|
| `FOG_TOTAL_{C,D,N,T}I` | 0.005 | 0.020 | 0.005 | 0.020 | 0.020 | 0.000 | 0.005 |
| `FOG_VERTICAL_CI` | 0.080 | 0.010 | 0.025 | 0.010 | 0.010 | 0.000 | 0.080 |
| `FOG_VERTICAL_DI` | 0.080 | 0.010 | 0.025 | 0.010 | 0.010 | 0.000 | 0.080 |
| `FOG_VERTICAL_NI` | 0.020 | 0.010 | 0.025 | 0.010 | 0.010 | 0.000 | 0.020 |
| `FOG_VERTICAL_TI` | 0.040 | 0.010 | 0.025 | 0.010 | 0.010 | 0.000 | 0.040 |

### Notes on the Defaults

- The wildcard dimension starts as a copy of the Overworld, except for the star day and twilight intensities (`2.0` and `3.0` instead of `0.0` and `2.0`).
- `-4` sets all fog densities to `0.000`. A vertical density of `0` currently divides by zero in the atmospheric fog calculation; this is tracked in [TODO.md](../TODO.md).
- The Day, Night, and Twilight values of a dimension with `DAYCYCLE` set to `0` are unused. Only the Constant values apply.

---

## Color Pipeline

Adapters return **linear** colors. Each time-of-day value is converted once:

```glsl
toLinear(vec3(R, G, B) * (I / 255.0))
```

and the results are blended with `lerp` (a three-point mix over `dayCycle`, 0 to 2) in linear space. Blending after conversion gives a different intermediate color than blending sRGB values and then converting, and the result is what the shader now uses.

Sky and lens flare code still work in sRGB. They receive `sRGB*Col` varyings computed in the vertex stage with `toSRGB(max(x, 1e-6))`, because `toSRGB(0.0)` produces NaN.

| Helper | Definition | Notes |
|---|---|---|
| `toLinear(x)` | `((2.10545 + x) * (0.0231872 + x)) * x * 0.315206` | Polynomial; constant-folds for constant inputs |
| `toSRGB(x)` | `(inversesqrt(x) - 0.126893) * x * 1.14374` | Undefined at `0.0` |

---

## Vanilla Fog Color

When `VANILLAFOG` is `1`, the adapter reads the vanilla fog color as `toLinear(fastSqrt(fogColor))`, where `fastSqrt(x) = x * (2.0 - x)`.

| `VANILLAFOG_MODE` | Result |
|---|---|
| `0` Replace | Vanilla fog color only. `VANILLAFOG_STRENGTH` is ignored |
| `1` Blend | `mix(baseSky, fog, STRENGTH)` |
| `2` Multiply | `baseSky * mix(vec3(1.0), fog, STRENGTH)` |

`baseSky` is the Day, Night, and Twilight blend, or the Constant color when the day cycle is off. Only the Nether defaults to mode `1`; Limbo and Personal pockets default to mode `0`.

---

## Rules for Consumers

1. **Flags are 0 or 1 values.** Use `#if WORLD_X == 1`. Never use `#ifdef WORLD_X`, which is true for every dimension because the macro is always defined.
2. **Declarations are conditional.**

| Name | Declared only when |
|---|---|
| `dayCycle`, `twilightPhase`, `dayCycleAdjust` | `WORLD_DAYCYCLE == 1` |
| `rainStrength` | `WORLD_WEATHER == 1` |
| `fogColor` | `WORLD_VANILLAFOG == 1` |

3. **Use the adapters.** Call `worldSkyColor()`, `worldLightColor()`, and the other adapter functions rather than reading `WORLD_SKY_*` or `WORLD_LIGHT_*` directly.
4. **Keep an option's cost compile-time.** Gate code with the flag so an unused feature is not compiled for dimensions that disable it. See [OPTIMIZATION.md](OPTIMIZATION.md).

---

## Adding a Dimension

1. Copy an existing folder (`world0` is the most complete) to `shaders/world<id>/`.
2. In `world.glsl`, set `WORLD_ID` and `WORLD_PREFIX` to a new unique prefix, then rename every option to that prefix. Menu options with the same name in different files are one option, so the prefix must be unique.
3. Add the dimension to `shaders/dimension.properties`.
4. Add the screens to `shaders/shaders.properties` and the labels to `shaders/lang/en_US.lang`. Each dimension screen follows the layout in [SETTINGS.md](SETTINGS.md#configuration).
5. Check that all 59 options are defined, since a missing one is a compile error only in that dimension.

---

## Portability Note

The resolver relies on `##` token pasting inside a macro. It is established practice in preprocessors, but the shader language specification for the GLSL version this pack targets is not explicit about it. It is confirmed on Intel and AMD. NVIDIA and Mesa are untested. If a driver rejects it, the fallback is generating each dimension's `WORLD_*` defines directly in `world.glsl`.
