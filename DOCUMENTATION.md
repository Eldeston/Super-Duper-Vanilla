# Coding Standards
These standards must be kept in order to keep the code format consistent and readable.

* Minimizing resources and maximizing performance is top priority. Quality is secondary.
* Follow the rules of code formatting. See [CONTRIBUTION.md](CONTRIBUTION.md) for more information.
* Document and explain your code if possible.

# GLSL Version
The shader version used for this pipeline is **GLSL 3.3 compatibility**. There is an exception however for the program `gbuffers_line` where it uses **GLSL 3.3 core**.

For more information of the specifications of this version see this [documentation provided by Khronos](https://registry.khronos.org/OpenGL/specs/gl/GLSLangSpec.3.30.pdf).

# Used Buffers
Current shader pipeline uses 6 framebuffers to minimize resources used and maximize performance. Their usages are listed in order of what's written first separated by forward slashes and channels separated by commas.

| Buffers   | Format         | Usage                                                                             |
| --------- | -------------- | --------------------------------------------------------------------------------- |
| colortex0 | R11F_G11F_B10F | Clouds (RG) / Bloom (RGB)                                                         |
| colortex1 | RGB16_SNORM    | Normals (RGB)                                                                     |
| colortex2 | RGBA8          | Albedo (RGB), SSAO (A)                                                            |
| colortex3 | RGB8           | Metal (R), Smooth (G), Glow / Translucents mask (B) / Main LDR (RGB) / FXAA (RGB) |
| colortex4 | R11F_G11F_B10F | Main HDR (RGB) / Vanilla skybox (RGB)                                             |
| colortex5 | RGBA16F        | TAA (RGB) / Previous frame (RGB), Auto exposure (A)                               |

# Custom Defined Macros
This shader uses custom defined macros in every program and .glsl file for each world folders all connected to the main programs in the main folder. This is to keep the workflow minimized and understandable, and to identify what folder/program the shader is being used.

## Dimension Macros
Found in all world.glsl files. Dimension macros define the world's lighting properties. These are not finalized and are still a work in progress as they tend to be inconsistent thus the reason of it being not available to the common user.

| Dimension Macros    | Data Type | Usage                   |
| ------------------- | --------- | ----------------------- |
| WORLD_ID            | int       | World ID                |
| WORLD_LIGHT         | none      | World enabled shadows   |
| WORLD_SUN_MOON      | int       | World light source type |
| WORLD_SUN_MOON_SIZE | float     | World light source size |

## Complex Programs
List of programs with complex lighting. Common complex processes are in these programs. They compute complex processes such as PBR and vertex displacement for animations and tend to be very expensive.

## Basic Programs
List of programs with basic lighting. Common basic processes are in these programs. They compute basic processes that complex programs have, but with removed features that the program doesn't necessarily need.

## Simple programs
List of programs with simpler shading. Common simple processes are in these programs. As the name suggests, they compute very simple and fast processes. The reason is usually because they don't need additional features as they tend to slow GPU performance.

## Disabled programs
List of discarded and disabled programs. They typically have no other purposes other than disabling a program by using `discard;` + `return;`. This method is used to conveniently disable programs without using `shaders.properties` to disable the program per world.

## Program Properties
Found in their respective programs in .fsh and .vsh files. The following are the listed common program macros. These macros typically describes the program and its properties.

This list's purpose is to fully realize the shader pipeline (based on Iris) and visualize the flow of data across programs and their purpose.

### Before Gbuffers
| Program Macros        | Blend Type  | Program Type     | Shading Type | Usage            |
| --------------------- | ----------- | ---------------- | ------------ | ---------------- |
| PHYSICS_OCEAN_SHADOW  | Solid       | PHYSICS_SHADOW   | Shadow       | Physics Mod      |
| SHADOW_BLOCK          | Solid       | SHADOW           | Shadow       | Iris             |
| SHADOW_CUTOUT         | Solid       | SHADOW           | Shadow       | Iris/Optifine    |
| SHADOW_ENTITIES       | Solid       | SHADOW           | Shadow       | Iris             |
| SHADOW_LIGHTNING      | Solid       | SHADOW           | Disabled     | Iris             |
| SHADOW_SOLID          | Solid       | SHADOW           | Shadow       | Iris/Optifine    |
| SHADOW_WATER          | Solid       | SHADOW           | Shadow       | Iris             |
| SHADOW                | Solid       | SHADOW           | Shadow       | Iris/Optifine    |

### Before Deferred
| Program Macros        | Blend Type  | Program Type     | Shading Type | Usage            |
| --------------------- | ----------- | ---------------- | ------------ | ---------------- |
| DH_TERRAIN            | Solid       | DH_GBUFFERS      | Complex      | Distant Horizons |
| DH_GENERIC            | Solid       | DH_GBUFFERS      | Basic        | Distant Horizons |
| VOXY_OPAQUE           | Solid       | VOXY_PIPELINE    | Complex      | Voxy             |
| ARMOR_GLINT           | Add         | GBUFFER          | Simple       | Iris/Optifine    |
| BASIC                 | Solid       | GBUFFER          | Basic        | Iris/Optifine    |
| BEACON_BEAM           | Add         | GBUFFER          | Simple       | Iris/Optifine    |
| DAMAGED_BLOCK         | Solid       | GBUFFER          | Simple       | Iris/Optifine    |
| LINE                  | Solid       | GBUFFER          | Basic        | Iris/Optifine    |
| SKY_BASIC             | Solid       | GBUFFER          | Disabled     | Iris/Optifine    |
| SKY_TEXTURED          | Solid       | GBUFFER          | Simple       | Iris/Optifine    |
| TERRAIN               | Solid       | GBUFFER          | Complex      | Iris/Optifine    |
| DEFERRED(0-99)        | None        | DEFERRED         | Post         | Iris/Optifine    |

## Mixed
| Program Macros        | Blend Type  | Program Type     | Shading Type | Usage            |
| --------------------- | ----------- | ---------------- | ------------ | ---------------- |
| PARTICLES             | Transparent | GBUFFER          | Basic        | Iris             |
| ENTITIES              | Transparent | GBUFFER          | Complex      | Iris/Optifine    |
| BLOCK                 | Transparent | GBUFFER          | Complex      | Iris/Optifine    |
| HAND                  | Transparent | GBUFFER          | Complex      | Iris/Optifine    |

### Before Composite
| Program Macros        | Blend Type  | Program Type     | Shading Type | Usage            |
| --------------------- | ----------- | ---------------- | ------------ | ---------------- |
| PHYSICS_OCEAN         | Solid       | PHYSICS_GBUFFERS | Complex      | Physics Mod      |
| DH_WATER              | Transparent | DH_GBUFFERS      | Complex      | Distant Horizons |
| VOXY_TRANSLUCENT      | Transparent | VOXY_PIPELINE    | Complex      | Voxy             |
| CLOUDS                | Transparent | GBUFFER          | Simple       | Iris/Optifine    |
| LIGHTNING             | Add         | GBUFFER          | Basic        | Iris             |
| TEXTURED              | Transparent | GBUFFER          | Basic        | Iris/Optifine    |
| SPIDER_EYES           | Add         | GBUFFER          | Simple       | Iris/Optifine    |
| WATER                 | Transparent | GBUFFER          | Complex      | Iris/Optifine    |
| WEATHER               | Transparent | GBUFFER          | Simple       | Iris/Optifine    |
| COMPOSITE(0-99)       | None        | COMPOSITE        | Post         | Iris/Optifine    |

Note to Eldeston: Clarify program names with its purpose.

# Incompatible Mods
List of incompatible mods.

| Mods       | Compatibility | Status       |
| ---------- | ------------- | ------------ |
| Astrocraft | Visual bug    | Low priority |
| Nuit       | Visual bug    | Low priority |

# TO DO (for Eldeston)
Notes for pending features/bug fixes to be implemented categorized by importance.

## PENDING
* Create a custom shadow model view (low priority)
* Fix gbuffers_skytextured (medium priority)

* Find a way to make translucent detection more dynamic (medium priority)

* Improve world properties calculation
* Improve settings UI

* Rebuild pipeline and include visualization (high priority)
* Document the shader pipeline (high priority)

* Separate iPBR for all gbuffers (medium priority)

* Optimize alpha testing (high priority)
* Optimize DOF calculations with noise (low priority)
* Optimize block ids in block.properties (medium priority)
* Optimize day and night transition calculations (medium priority)

* Refactor uniform usage and remove unecessary ones (medium priority)
* Format the goodness knows how much nesting I used in my code because BROTHA EWWHH (maximum priority)

## CURRENT
* Refactor parallax occlusion mapping
* Change cloud texture

* Improve fog calculation and settings (medium priority)
* Improve water absorption (low priority)
* Improve tonemapping (medium priority)
* Improve Distant Horizons depth
* Improve subsurface scattering
* Improve shadow filtering
* Improve shader menu UI

## DONE
* Full compatibility with Voxy LOD mod (voxy.json pipeline across world0/world-1/world1, custom UBO layout, PBR materials, depthTex fallbacks, borderFar atmospheric fog integration, seamless sunlight matching, and SSR reflection loop prevention)
* Implement bit packing & encoding library (`shaders/lib/utility/bitPacking.glsl`) for octahedral normals, 2x8/4x8/2x16 UNORM data, lightmaps, and PBR material flags
* Consolidate FXAA into final.glsl and eliminate composite7 pass across dimensions
* Specular & smoothness guard in deferred1 and composite passes to bypass matte albedo/normal lookups
* Eliminate transcendental powers in skyRender and SSR bisection lookups in rayTracer
* Conditional pass elimination via `shaders.properties` (`program.<name>.enabled = false`) for inactive passes (composite2 motion blur, composite3 DOF, composite4/5 bloom, deferred SSAO, shadow passes)
* Frustum bounding box early-exit checks in `shdMapping.glsl` to avoid sampling shadow maps outside light projection bounds
* View frustum depth bounds check `[0.0, 1.0]` in `rayTracer.glsl` to stop raymarching past far plane or behind camera
* Front-facing normal check (`NV > 0.0`) in `complexShadingDeferred.glsl` to prevent SSR raymarches on backfacing surfaces

* Finish programming dh_generic (medium priority)

* Fix dragon death beam (medium priority) ?
* Fix FXAA, it was broken the whole time (high priority)

* Implement portal depth for Nether and End

# Performance Profiling & Optimization Tooling

Performance and resource efficiency are top priority in Super Duper Vanilla. The following instrumentation stack is configured for testing and continuous optimization:

## In-Game Profiling & Instrumentation

* **Spark Profiler**:
  - Measures CPU performance, tick rate, render thread execution, and GC allocation churn.
  - Client Commands:
    - `/sparkc profiler start` — Start sampling client threads (render thread, worker threads).
    - `/sparkc profiler stop` — Stop sampling and generate an online call-tree flame graph.
    - `/sparkc health` — View TPS, tick times, system RAM, CPU load, and GC metrics.
    - `/sparkc heapsummary` — Inspect heap allocation rates to eliminate GC pause stutters.
    - `/sparkc tickmonitor` — Monitor real-time frame/tick latency spikes.
* **Iris Live Reload & Debug Options**:
  - **Instant Live Reload**: Press `R` in-game to recompile modified shaders in real time without restarting Minecraft.
  - **F3 Debug Overlay**: Displays active shader program names, pass timings, and shadow map metrics.
  - **Wireframe Mode**: Debug geometry tessellation and depth boundaries.
  - **OpenGL Driver Diagnostics**: Driver warnings and `KHR_debug` callbacks logged to `run/client/logs/latest.log`.
* **Sodium Extra Performance HUD**:
  - Real-time on-screen FPS display with minimum and average frame time tracking.
* **Graphics Debugger Injection (RenderDoc & NVIDIA Nsight Graphics)**:
  - `task run:renderdoc` — Launch with RenderDoc hooked for frame capture, draw call inspection, and texture analysis.
  - `task run:nsight` — Launch with NVIDIA Nsight Graphics hooked for GPU hardware performance counter profiling.

## Offline Shader Analysis & Static Profiler

* **Shader Performance Profiler** (`task profile` / `scripts/profile_shaders.py`):
  - Preprocesses all shaders across Overworld, Nether, and End dimensions.
  - Quantifies GPU cost drivers: texture fetch counts, distinct samplers, transcendental math operations (`pow`, `exp`, `sin`, `cos`, `atan`, `inverse`), loop iterations, and branching.
  - Computes weighted GPU Cost Index ranking every pass from heaviest to lightest.
  - Flags actionable optimization opportunities (e.g. `pow(x, 2.0)` -> `x * x`, high texture fetch pressure).
  - Supports `--json` export and `--compare baseline.json current.json` to benchmark optimization wins before and after code changes.