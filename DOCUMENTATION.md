# Formatting Standards
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
The following are the programs that run before gbuffers which are typically the shadow programs.

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
The following are the programs that run before deferred which are typically the solid gbuffer programs. This is where most of the forward rendering and everything about PBR happen.

| Program Macros        | Blend Type  | Program Type     | Shading Type | Usage            |
| --------------------- | ----------- | ---------------- | ------------ | ---------------- |
| DH_TERRAIN            | Solid       | DH_GBUFFERS      | Complex      | Distant Horizons |
| DH_GENERIC            | Solid       | DH_GBUFFERS      | Basic        | Distant Horizons |
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
The following are the programs that run before deferred which are typically the translucent/solid gbuffer programs. This is where most of the forward rendering and everything about PBR happen. This section is called mix because despite being translucent, they render before deferred instead of composite.

| Program Macros        | Blend Type  | Program Type     | Shading Type | Usage            |
| --------------------- | ----------- | ---------------- | ------------ | ---------------- |
| PARTICLES             | Transparent | GBUFFER          | Basic        | Iris             |
| ENTITIES              | Transparent | GBUFFER          | Complex      | Iris/Optifine    |
| BLOCK                 | Transparent | GBUFFER          | Complex      | Iris/Optifine    |
| HAND                  | Transparent | GBUFFER          | Complex      | Iris/Optifine    |

### Before Composite
The following are the programs that run before composite which are typically the translucent gbuffer programs. This is where most of the forward rendering and everything about PBR happen.

| Program Macros        | Blend Type  | Program Type     | Shading Type | Usage            |
| --------------------- | ----------- | ---------------- | ------------ | ---------------- |
| PHYSICS_OCEAN         | Solid       | PHYSICS_GBUFFERS | Complex      | Physics Mod      |
| DH_WATER              | Transparent | DH_GBUFFERS      | Complex      | Distant Horizons |
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

* Rebuild pipeline and include visualization (high priority)

* Separate iPBR for all gbuffers (medium priority)

* Optimize DOF calculations with noise (low priority)
* Optimize block ids in block.properties (medium priority)
* Optimize day and night transition calculations (medium priority)

* Refactor uniform usage and remove unecessary ones (medium priority)
* Format the goodness knows how much nesting I used in my code because BROTHA EWWHH (maximum priority)

## CURRENT
* Implement bit packing for optimization

* Refactor parallax occlusion mapping
* Change cloud texture

* Improve fog calculation and settings (medium priority)
* Improve water absorption (low priority)
* Improve tonemapping (medium priority)
* Improve Distant Horizons depth
* Improve shader menu UI
* Improve documentation (high priority)
* Implement Voxy support

* Find a way to separate sky light and terrain light, or implement a void sky property with permanent terrain light
* Replace skybox clouds completely with voxelized clouds
* Improve albedo calculation, separating it from getPBR(), also improve parallax occlusion mapping

## DONE
* Abandon Optifine support (high priority)

* Optimize alpha testing (high priority)

* Finish programming dh_generic (medium priority)
* Fix dragon death beam (medium priority) ?
* Fix FXAA, it was broken the whole time (high priority)

* Implement portal depth for Nether and End
* Improve subsurface scattering
* Improve shadow filtering