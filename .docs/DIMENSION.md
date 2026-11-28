# Dimension Configuration

**Scope**: How each dimension is configured, and what every per-dimension option does  
**Related Docs**: [SETTINGS.md](SETTINGS.md) | [ARCHITECTURE.md](ARCHITECTURE.md) | [PROGRAMS.md](PROGRAMS.md) | [FEATURES.md](FEATURES.md)

---

## Table of Contents

1. [Overview](#overview)
2. [Dimension Mapping](#dimension-mapping)
3. [Configuration Layers](#configuration-layers)
4. [Option Reference](#option-reference)
5. [Color Pipeline](#color-pipeline)
6. [Vanilla Fog Color](#vanilla-fog-color)
7. [Rules for Consumers](#rules-for-consumers)
8. [Adding a Dimension](#adding-a-dimension)
9. [Portability Note](#portability-note)

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

Suffix convention: **C** = constant (used when the day cycle is off), **D** = day, **N** = night, **T** = twilight. Ranges and defaults are set by each dimension's `world.glsl` and shown in the shader menu, so they are not repeated here.

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

`SKYLIGHT` polarity is deliberate: `1` means real skylight, and `0` means the dimension has no sky to sample, so `SKYLIGHT_I` is used as a constant instead.

### Basic

| Option | Meaning |
|---|---|
| `SKYLIGHT_I` | Constant skylight amount, used when `SKYLIGHT` is `0` |
| `CELESTIAL` | Celestial body drawn in the sky and used for the lens flare and specular highlight: `0` None, `1` Sun/Moon, `2` Black hole |
| `CELESTIAL_SIZE` | Size of the celestial body, including the size of its specular reflection |
| `VANILLAFOG_MODE` | How the vanilla fog color combines with the sky: `0` Replace, `1` Blend, `2` Multiply. See [Vanilla Fog Color](#vanilla-fog-color) |
| `VANILLAFOG_STRENGTH` | Amount of fog color applied in modes `1` and `2`. Ignored by mode `0` |

### Stars

`STAR_CI`, `STAR_DI`, `STAR_NI`, and `STAR_TI` set the star brightness for the constant, day, night, and twilight states. They only matter when `STARS` is `1`, and `STAR_CI` only when `DAYCYCLE` is `0`.

### Light and Sky Colors

Each time state has a color and an intensity for the directional light and for the sky:

| Pattern | Meaning |
|---|---|
| `LIGHT_{C,D,N,T}{R,G,B}` | Red, green, and blue of the directional light (sun or moon), on a 0 to 255 scale |
| `LIGHT_{C,D,N,T}I` | Intensity multiplier of that light |
| `SKY_{C,D,N,T}{R,G,B}` | Red, green, and blue of the sky, on a 0 to 255 scale |
| `SKY_{C,D,N,T}I` | Intensity multiplier of that sky color |

The directional light drives direct lighting, specular highlights, volumetric lighting, and the lens flare. The sky color is the sky itself and also the ambient light that skylight lets in. Each state's color is `RGB * (I / 255)`, converted to linear (see [Color Pipeline](#color-pipeline)).

### Fog

| Pattern | Meaning |
|---|---|
| `FOG_TOTAL_{C,D,N,T}I` | Overall atmospheric fog density |
| `FOG_VERTICAL_{C,D,N,T}I` | How quickly fog thins out with height. Larger values keep the fog closer to the ground |

Both are used by the atmospheric fog calculation in `lib/atmospherics/fogRender.glsl`.

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

## Color Pipeline

Adapters return **linear** colors. Each time-of-day value is converted once:

```glsl
toLinear(vec3(R, G, B) * (I / 255.0))
```

and the results are blended with `lerp` (a three-point mix over `dayCycle`, 0 to 2) in linear space. Blending after conversion gives a different intermediate color than blending sRGB values and then converting, and the result is what the shader now uses.

Sky and lens flare code still work in sRGB. They receive `sRGB*Col` varyings computed in the vertex stage with `toSRGB` from the linear adapter values.

| Helper | Definition | Notes |
|---|---|---|
| `toLinear(x)` | `((2.10545 + x) * (0.0231872 + x)) * x * 0.315206` | Polynomial; constant-folds for constant inputs |
| `toSRGB(x)` | `(inversesqrt(x) - 0.126893) * x * 1.14374` | Inverse of `toLinear` |

---

## Vanilla Fog Color

When `VANILLAFOG` is `1`, the adapter reads the vanilla fog color as `toLinear(fastSqrt(fogColor))`, where `fastSqrt(x) = x * (2.0 - x)`.

| `VANILLAFOG_MODE` | Result |
|---|---|
| `0` Replace | Vanilla fog color only. `VANILLAFOG_STRENGTH` is ignored |
| `1` Blend | `mix(baseSky, fog, STRENGTH)` |
| `2` Multiply | `baseSky * mix(vec3(1.0), fog, STRENGTH)` |

`baseSky` is the Day, Night, and Twilight blend, or the Constant color when the day cycle is off.

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
