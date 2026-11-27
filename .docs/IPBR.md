# Integrated PBR (iPBR)

**Scope**: How Super Duper Vanilla derives PBR materials from vanilla textures and block/entity IDs, the ID map, the per-material rules, and how to add a material  
**Related Docs**: [PROGRAMS.md](PROGRAMS.md) | [SETTINGS.md](SETTINGS.md) | [OPTIMIZATION.md](OPTIMIZATION.md) | [ARCHITECTURE.md](ARCHITECTURE.md)

> iPBR is scheduled for a redesign (see [TODO.md](../TODO.md)). This document describes the system as it exists in the code today.

---

## Table of Contents

1. [Overview](#overview)
2. [PBR Modes](#pbr-modes)
3. [ID System](#id-system)
4. [Material Data](#material-data)
5. [Block Materials](#block-materials)
6. [Entity Materials](#entity-materials)
7. [Special Blocks](#special-blocks)
8. [Generated Normals](#generated-normals)
9. [Procedural Surfaces](#procedural-surfaces)
10. [Environment PBR](#environment-pbr)
11. [Adding a Material](#adding-a-material)
12. [Known Mismatches](#known-mismatches)

---

## Overview

iPBR gives vanilla resource packs PBR without any extra textures. A block or entity is identified by an ID assigned in `block.properties` or `entity.properties`. The fragment shader reads the vanilla albedo, then `getPBR(material, id)` picks a rule for that ID and derives smoothness, metallic, emissive, and subsurface values from the albedo colors.

```
block.properties / entity.properties
        |   (ID per block or entity)
        v
vertex stage: blockId / blockEntityId / entityId
        |
        v
fragment stage: getPBR(material, id)   <- lib/PBR/integratedPBR.glsl
        |   (fills dataPBR from the albedo)
        v
enviroPBR(...)   (optional rain wetness)
        |
        v
complexShadingForward(material, ...)
```

| File | Role |
|---|---|
| `shaders/block.properties` | Block IDs, tags, and the animation ID groups |
| `shaders/entity.properties` | Entity IDs |
| `shaders/lib/PBR/dataStructs.glsl` | The `dataPBR` struct |
| `shaders/lib/PBR/integratedPBR.glsl` | `getPBR` for integrated PBR, plus the ore overlay helpers |
| `shaders/lib/PBR/labPBR.glsl` | `getPBR` for resource pack PBR (LabPBR 1.3) |
| `shaders/lib/PBR/enviroPBR.glsl` | Rain wetness |

Both PBR files define a function named `getPBR`, and a program includes exactly one of them:

```glsl
#if PBR_MODE <= 2
    #include "/lib/PBR/integratedPBR.glsl"
#else
    #include "/lib/PBR/labPBR.glsl"
#endif
```

Programs that include it: `gbuffers_terrain`, `gbuffers_block`, `gbuffers_hand`, `gbuffers_water`, and `gbuffers_entities`.

---

## PBR Modes

| `PBR_MODE` | Menu label | Behavior |
|---|---|---|
| `0` | OFF | Uses the integrated file (see [Known Mismatches](#known-mismatches)) |
| `1` | Basic PBR | Integrated PBR without rough reflections for stone, soil, and concrete families |
| `2` | Integrated PBR | Basic PBR plus smoothness for stone, soil, concrete, and terracotta families, when `ROUGH_REFLECTIONS` is on |
| `3` | Lab PBR 1.3 | Reads the resource pack's PBR textures through `labPBR.glsl` |

Most per-block rules are inside `#if PBR_MODE <= 2`. A smaller set is outside it and applies to every integrated mode: default material values, vanilla AO, lava and fire emission, subsurface for foliage and corals, water, and the Nether portal. These are the "Default" IDs in `block.properties`.

---

## ID System

### Rules (from `block.properties`)

- Block IDs take priority over tags. A tag is ignored for blocks already listed by ID.
- Tags are only for simple materials, never for per-pixel ones.
- A block must not appear in two IDs, and block IDs should not use pre-1.13 legacy names.
- IDs with no blocks assigned are left empty for user input.
- The maximum ID is `32767`.
- Entity IDs start at `20000`, so a block and an entity never share an ID.

### Ranges

| Range | Use |
|---|---|
| `10000` to `11999` | Animation groups. Exclusive: each ID selects a vertex animation |
| `12000` to `12099` | Special effects (end portal, signs) |
| `12100` to `12299` | Default group: applies in every integrated mode |
| `12300` to `12599` | Simple materials (whole-block rules) |
| `12600` to `13399` | Complex materials (per-pixel rules: ores, emissives) |
| `14000` to `14002` | Dimensional Doors blocks (Kawwabi) |
| `20000` and above | Entities |

The animation IDs also carry material meaning. Foliage, vines, and corals receive full subsurface scattering from their animation IDs:

```glsl
(id >= 10000 && id <= 10800) || (id >= 11200 && id <= 11799)
    || id == 10900 || id == 11101 || id == 12200   // material.ss = 1.0
```

Lava (`11100`) and fire (`12101`) are emissive at `1.0`.

---

## Material Data

`dataPBR` holds everything `getPBR` fills in:

| Field | Meaning |
|---|---|
| `albedo` | Texture color (`vec4`) |
| `normal` | Normal, defaults to the surface normal |
| `metallic` | Metalness |
| `smoothness` | Smoothness (1 − roughness) |
| `emissive` | Emission amount, scaled later by `EMISSIVE_INTENSITY` |
| `ambient` | Ambient occlusion. Terrain uses vanilla vertex AO, everything else uses `1.0` |
| `porosity` | Wetness porosity, used by [Environment PBR](#environment-pbr) |
| `ss` | Subsurface scattering amount |
| `parallaxShd` | Parallax self-shadow, `1.0` by default |

Default material: `smoothness 0`, `emissive 0`, `metallic 0.04`, `porosity 0`, `ss 0`.

Common derived values inside `getPBR`: `albedoSum` (R+G+B), `albedoMax`, and `albedoMin`. Most rules are one of those scaled into smoothness or emission.

---

## Block Materials

`TERRAIN` and `BLOCK` programs run most of these. Rules marked *mode 2* require `PBR_MODE == 2` and `ROUGH_REFLECTIONS`.

### Default Group

| ID | Blocks | Rule |
|---|---|---|
| `12100` | Nether, Undergarden, and Twilight Forest portals | `emissive = average albedo`, `smoothness 0.96` (water program) |
| `12101` | Fire, soul fire | `emissive 1.0` |
| `12102` | Potted crimson and warped fungus | Fungus emission |
| `12103` | Potted torchflower | Torchflower emission |
| `12200` | Kelp, seagrass | `ss 1.0` |

### Emissive Blocks

| ID | Blocks | Rule |
|---|---|---|
| `12300` | Froglights | `emissive = cubed(max(0, albedoSum * 4/3 - 3))`, `smoothness 0.9` |
| `12301` | Shroomlight, sea lantern, glowstone, lamps | `emissive = saturate(albedoSum * 4/3 - 2)`, `smoothness 0.9` |
| `12302` | Creaking heart | Emission from red and green against blue |
| `12303` | Redstone block | `emissive = R * 0.25`, metallic, smooth by `sqrt(R)` |
| `12304` | Raid den crystal (modded, `BLOCK` only) | `emissive = cubed(albedoMax) * 0.25`, `smoothness 0.9` |
| `12305` | Amethyst blocks | Very steep luminance emission, `metallic 0.17` |
| `12306` | Amethyst buds | Same as above with a quarter of the base emission |

### Metallic Blocks

| ID | Blocks | Smoothness |
|---|---|---|
| `12400` | Netherite, ancient debris, cauldrons, hopper, anvils, chains | `albedoSum * 0.1999 + 0.4` |
| `12401` | Iron, gold, brass, pressure plates, spawners, vaults | `albedoSum * 0.3 + 0.06` |
| `12402` | Copper family, chests, rods, statues | `max(R, G) * 0.96` |
| `12403` | Copper bulbs | Copper, plus emission from the lit color |

All have `metallic 1.0`.

### Smooth, Glass, and Ice

| ID | Blocks | Rule |
|---|---|---|
| `12500` | Glass, panes, tinted glass | `sqrt(albedoMax) * 0.96` (water and block programs) |
| `12501` | Diamond, emerald, lapis, and similar crystal blocks; obsidian | `metallic 0.17`, `sqrt(min(0.8, albedoSum))` |
| `12516` | Packed ice, blue ice | `ss = albedoMax`, `smoothness = average * 0.96` |
| `12550` | Slime, honey | Translucent jelly: `ss`, smoothness from the average |
| `12551` | Ice, frosted ice | `ss` and `smoothness = albedoMax * 0.96` |

### Stone Families

Base blocks only get smoothness in *mode 2*. Ore variants overlay on top of their host (see [Ores](#ores)).

| ID | Family | Smoothness (mode 2) |
|---|---|---|
| `12502` | Stone, cobblestone, bricks, coal ore, and others | `albedoMin * 0.6` |
| `12503` | Deepslate | `albedoMax * 0.75` |
| `12504` | Granite | `albedoMax * 0.6` |
| `12505` | Diorite | `albedoMin * 0.45` |
| `12506` | Andesite | `albedoMin * 0.6` |
| `12507` | Tuff | `albedoMax * 0.6` |
| `12508` | Blackstone | `albedoMax * 0.75` |
| `12509` | Basalt | `albedoMax * 0.6` |
| `12510` | Quartz, glazed terracotta | `albedoMin * 0.75` |
| `12511` | Purpur | `albedoMax * 0.9` |
| `12512` | Calcite | `albedoMin * 0.45` |
| `12513` | Prismarine | `albedoMax * 0.9` |
| `12514` | Sulfur | `albedoMax * 0.6` |
| `12515` | Cinnabar | `albedoMax * 0.6` |
| `12517` | Snow | `ss` and smoothness (mode 2) from the average, scaled by `0.45` |
| `12518` | Soil, sand, netherrack, moss | `sqrt(albedoMax) * 0.3` |
| `12519` | Concrete, terracotta | `sqrt(average) * 0.15 + 0.3` |
| `12520` | Cactus, bamboo, sponge, honeycomb | `ss = sqrt(albedoSum) / 3` |

### Ores

Ore overlays only increase smoothness (`max` against the host's value). Each is picked by color test on the texture, so the stone part of the ore texture keeps the host's material.

| ID | Ores | Overlay |
|---|---|---|
| `12600` | Crystal ores (stone) | `oreCrystals`: `metallic 0.17`, smoothness from luminance |
| `12601` | Nether quartz ore | `oreCrystalsNether` |
| `12602` | Crystal ores (deepslate) | `oreCrystals` |
| `12700` | Metal ores (stone) | `oreMetals`: `metallic 1.0`, `max(R, G) * 0.96` |
| `12701` | Nether gold ore | `oreMetalsNether` |
| `12702` | Gilded blackstone | `oreGilded` |
| `12703` | Metal ores (deepslate) | `oreMetals` |
| `12800` | Redstone ore | `oreRedstone`: emission from red, `metallic 1.0` |
| `12801` | Redstone ore (deepslate) | `oreRedstone` |

### Other Emissives

| ID | Blocks | Rule |
|---|---|---|
| `12900` | Lit furnaces | `smoothen(max(0, albedoMax - 0.75) * 4)` |
| `12901` | Torches, lanterns, campfires, end rod, jack o'lantern | `emissive = (saturate(albedoSum * 5/6 - 1))^4` |
| `10801` | Hanging lanterns | Same rule as `12901` |
| `13000` | Redstone components | `oreRedstone` |
| `13001` | Redstone wire | Emission and smoothness from the vertex color's red |
| `13002` | Powered rails and similar | Metal, when the pixel is grey |
| `13100` | Glow lichen | `1.0` where red exceeds blue |
| `13101` | Warped stems | Emission on the glowing pixels |
| `13102` | Crimson stems | Emission on the glowing pixels |
| `13103` | Chorus flower (mature) | `ss` plus emission |
| `13104` | Chorus flower (growing) | `ss` plus exponential emission |
| `13107` | Chorus plant | `ss` only |
| `13105` | Common sculk | `emissive = cubed(B)`, `smoothness 0.45` |
| `13106` | Uncommon sculk | Same as common sculk |
| `13200` | Beacon | `exp(albedoSum * 8/3 - 8)` |
| `13201` | End portal frame | Emission on the eye pixels |
| `13300` | Crying obsidian | Crystal base plus `cubed(albedoMax)` emission |
| `10001` | Glow berries (cave vines) | Emission from the berry pixels |
| `10002`, `10601` | Weeping vines, fungus | `1.0` on bright pixels |
| `10602` | Torchflower | Emission on the red petals |

---

## Entity Materials

Entity IDs live in `entity.properties`, starting at `20000`.

| ID | Entities | Status |
|---|---|---|
| `20000` | Lightning bolts (including modded) | No material code yet |
| `20001` | Boats (vanilla and modded) | No material code yet |
| `20002` to `20006` | Endermite, witch, drowned, stray, ghast | No material code yet |
| `20100` | Whole-entity emission (experience orbs, fireballs, vex, allay, blaze, glow squid, and many modded) | `emissive = cubed(average albedo)` |
| `20101` | Iron golem | Metallic parts only: `metallic 1.0`, `smoothness = albedoSum * 0.3 + 0.06`; red pixels emit |
| `20102` | Snow golem | `ss` from the average, smoothness in mode 2 |
| `20200` | End crystal | Emission where red exceeds half of green plus blue |
| `20201` | Creepers (charged) | Emission where blue exceeds green |
| `20202` | Copper golem | `metallic 1.0`, `max(R, G) * 0.96` |

Entity candidates that could get materials later, and notes on minecarts, are kept as comments at the top of `entity.properties`.

---

## Special Blocks

| ID | Block | Handling |
|---|---|---|
| `12000` | End portal, end gateway | Procedural end portal in `gbuffers_block` (a `blockEntityId` check) |
| `14001` | Dimdoors portal | Same procedural portal as `12000` |
| `12001` | Signs | Reserved for a sign text fix, unused |
| `11103` | Dimdoors eternal fluid | Unshaded pass (see below) |
| `14000` | Dimdoors fabric | Unshaded pass |
| `14002` | Dimdoors unravelled and ancient fabric | Unshaded pass |

The unshaded pass in `gbuffers_terrain` reads the texture, applies `toLinear`, writes it straight to scene color, and writes zero normals. This keeps every face perfectly uniform, with no SSAO edge shadows and no specular variation.

---

## Generated Normals

`NORMAL_GENERATION` builds a bump normal from the albedo by sampling three neighboring texels, and blends it with the geometric normal by `NORMAL_STRENGTH`. It works in the terrain, water, block, and translucent block programs, and skips lava (`11100`), water (`11102`), and fire (`12101`).

`NORMAL_GENERATION_RESOLUTION` (`16` to `1024`) is the assumed texture resolution used for the sampling offset. Its performance cost is minor. It is part of integrated PBR only.

---

## Procedural Surfaces

Some surfaces replace or modulate the texture procedurally. Their settings are on the iPBR page of the menu ([SETTINGS.md](SETTINGS.md#ipbr-material-subpages)).

| Surface | Options |
|---|---|
| Water | Noise, brightness, normal blur and depth, tile size, stylized absorption, foam, flat albedo |
| Lava | Brightness, noise, tile size |
| Sculk | Brightness, noise, tile size |

Lava is processed in `gbuffers_terrain` on ID `11100`.

---

## Environment PBR

`ENVIRONMENT_PBR` is available when `WORLD_WEATHER == 1` and applies a rain-wet look on upward-facing surfaces with high skylight (the lightmap sky value above `0.8`):

```glsl
rainMatFact = (1.0 - porosity) * skyLightDelta * isPrecipitationRain * normal.y * 5.0;
rainMatFact *= saturate(sumOf(noise.xy) - 0.5);   // patchy wetness
```

The factor pulls the normal toward the geometric normal, sets a small `metallic` floor (`0.02` scaled by the factor), pushes `smoothness` toward `0.96`, and darkens the albedo by up to half. Lava, fire, and water skip it. Distant Horizons and Voxy have their own call sites.

---

## Adding a Material

1. **Pick the ID.** Use an empty ID in the right range from [ID System](#id-system), or the next free number in the matching group. Never reuse a number.
2. **Assign blocks.** Add them to `block.properties` by block ID. Use a tag only for a simple material, and never for blocks already listed.
3. **Add the rule.** In `integratedPBR.glsl`, add an `else if(id == <ID>)` branch in the right section. Gate smoothness that depends on rough reflections with `#if PBR_MODE == 2 && defined ROUGH_REFLECTIONS`.
4. **Put it in the right program.** `TERRAIN || BLOCK` for per-pixel block rules, `WATER || BLOCK` for glass and ice, `ENTITIES` for entity rules.
5. **Prefer cheap math.** Derive values from `albedoSum`, `albedoMax`, and `albedoMin`, which are computed once per fragment.
6. **Test with a resource pack off and on**, because the rules read the texture colors and a pack changes them.

---

## Known Mismatches

These are differences between the code and the ID files as they currently stand. Remove an entry here once it is fixed.

- **`PBR_MODE 0` is not separate.** Nothing tests `PBR_MODE > 0`, so mode `0` runs the same integrated path as mode `1`.
- **`labPBR.glsl` uses old entity IDs.** It tests `10130`, `10131`, and `10132` for whole-entity emission, the end crystal, and the charged creeper. `entity.properties` now uses `20100`, `20200`, and `20201`.
- **Sculk IDs in `gbuffers_terrain`.** The sculk noise and the darker-side tweak test `13005` and `13202`, but `block.properties` assigns sculk to `13105` and `13106`. Those two checks never match.
- **Signs.** `12001` is assigned but no code reads it.
- **Entities `20000` to `20006`.** They are assigned but no material code reads them yet.
