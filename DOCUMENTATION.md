## Coding Standards
   These standards must be kept in order to keep the code format consistent and readable.

* Minimizing resources and maximizing performance is top priority. Quality is secondary.
* Follow the rules of code formatting. See [CONTRIBUTION.md](CONTRIBUTION.md) for more information.
* Document and explain your code if possible.

## GLSL Version
   The shader version used for this pipeline is **GLSL 3.3 compatibility**. There is an exception however for the program `gbuffers_line` where it uses **GLSL 3.3 core**.

   For more information of the specifications of this version see this [documentation provided by Khronos](https://registry.khronos.org/OpenGL/specs/gl/GLSLangSpec.3.30.pdf).

## Used Buffers
   Current shader pipeline uses 6 framebuffers to minimize resources used and maximize performance. Their usages are listed in order of what's written first separated by forward slashes and channels separated by commas.

| Buffers   | Format         | Usage                                                                             |
| --------- | -------------- | --------------------------------------------------------------------------------- |
| gcolor    | R11F_G11F_B10F | Main HDR (RGB) / Vanilla skybox (RGB)                                             |
| colortex1 | RGB16_SNORM    | Normals (RGB)                                                                     |
| colortex2 | RGBA8          | Albedo (RGB), SSAO (A)                                                            |
| colortex3 | RGB8           | Metal (R), Smooth (G), Glow  /Translucents mask (B) / Main LDR (RGB) / FXAA (RGB) |
| colortex4 | R11F_G11F_B10F | Clouds (RG) / Bloom (RGB)                                                         |
| colortex5 | RGBA16F        | TAA (RGB) / Previous frame (RGB), Auto exposure (A)                               |

## Custom Defined Macros
   This shader uses custom defined macros in every program and .glsl file for each world folders all connected to the main programs in the main folder. This is to keep the workflow minimized and understandable, and to identify what folder/program the shader is being used.

### Dimension Macros
   Found in all world.glsl files. Dimension macros define the world's lighting properties. These are not finalized and are still a work in progress as they tend to be inconsistent thus the reason of it being not available to the common user.

| Dimension Macros    | Data Type | Usage                   |
| ------------------- | --------- | ----------------------- |
| WORLD_ID            | int       | World ID                |
| WORLD_LIGHT         | none      | World enabled shadows   |
| WORLD_SUN_MOON      | int       | World light source type |
| WORLD_SUN_MOON_SIZE | float     | World light source size |

### Complex Programs
   List of programs with complex lighting. Common complex processes are in these programs. They compute complex processes such as PBR and vertex displacement for animations and tend to be very expensive.

### Basic Programs
   List of programs with basic lighting. Common basic processes are in these programs. They compute basic processes that complex programs have, but with removed features that the program doesn't necessarily need.

### Simple programs
   List of programs with simpler shading. Common simple processes are in these programs. As the name suggests, they compute very simple and fast processes. The reason is usually because they don't need additional features as they tend to slow GPU performance.

### Disabled programs
   List of discarded and disabled programs. They typically have no other purposes other than disabling a program by using `discard;` + `return;`. This method is used to conveniently disable programs without using `shaders.properties` to disable the program per world.

### Program Properties
   Found in their respective programs in .fsh and .vsh files. The following are the listed common program macros. These macros typically only defines the program.

   This along with the `GBUFFERS` macro, are used to identify the quirks in the current program for the shader to detect.

   This list's purpose is to fully realize the shader pipeline and visualize the flow of data across programs and their purpose.

| Program Macros       | Blend Type  | Program Type | Shading Type |
| -------------------- | ----------- | ------------ | ------------ |
| DH_SHADOW            | solid       | GBUFFER      |              |
| SHADOW               | solid       | GBUFFER      |              |
| -------------------- | ----------- | ------------ | ------------ |
| DH_TERRAIN           | solid       | GBUFFER      | Complex      |
| ARMOR_GLINT          | add         | GBUFFER      | Simple       |
| BASIC                | solid       | GBUFFER      | Basic        |
| BEACON_BEAM          | add         | GBUFFER      | Simple       |
| DAMAGED_BLOCK        | solid       | GBUFFER      | Simple       |
| ENTITIES_GLOWING     | solid       | GBUFFER      | Complex      |
| ENTITIES             | solid       | GBUFFER      | Complex      |
| HAND                 | solid       | GBUFFER      | Complex      |
| LINE                 | solid       | GBUFFER      | Disabled     |
| SKY_BASIC            | solid       | GBUFFER      | Simple       |
| SKY_TEXTURED         | solid       | GBUFFER      | Simple       |
| SPIDER_EYES          | add         | GBUFFER      | Simple       |
| TERRAIN              | solid       | GBUFFER      | Complex      |
| DEFERRED(0-99)       | none        | DEFERRED     |              |
| -------------------- | ----------- | ------------ | ------------ |
| DH_WATER             | transparent | GBUFFER      | Complex      |
| BLOCK                | transparent | GBUFFER      | Complex      |
| CLOUDS               | transparent | GBUFFER      | Basic        |
| ENTITIES_TRANSLUCENT | transparent | GBUFFER      | Complex      |
| HAND_WATER           | transparent | GBUFFER      | Complex      |
| TEXTURED             | transparent | GBUFFER      | Basic        |
| WATER                | transparent | GBUFFER      | Complex      |
| WEATHER              | transparent | GBUFFER      | Simple       |
| COMPOSITE(0-99)      | none        | DEFERRED     |              |

Note to self: clarify program names with its purpose

## TO DO (for Eldeston)
* Refactor uniform usage and remove unecessary ones (medium priority)
* Optimize DOF calculations with noise (low priority)
* Create a custom shadow model view (low priority)
* Fix FXAA, it was broken the whole time (high priority)
* Optimize alpha testing (high priority)

* Optimize block ids in block.properties (medium priority)
* Rebuild pipeline and include visualization (high priority)
* Document the shader pipeline (high priority)
* Abandon Optifine support (high priority)

* Separate iPBR for gbuffers (low priority)

* Implement cloud absorption (low priority)
* Improve water absorption (low priority)
* Improve tonemapping (medium priority)
* Improve atmospheric fog (medium priority)