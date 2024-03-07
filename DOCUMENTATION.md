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

| Buffers   | Format         | Usage                                                         |
| --------- | -------------- | ------------------------------------------------------------- |
| gcolor    | R11F_G11F_B10F | Main HDR (RGB) / Vanilla skybox (RGB)                         |
| colortex1 | RGB16_SNORM    | Normals (RGB)                                                 |
| colortex2 | RGBA8          | Albedo (RGB), SSAO (A)                                        |
| colortex3 | RGB8           | Metal (R), Smooth (G), Glow (B) / Main LDR (RGB) / FXAA (RGB) |
| colortex4 | R11F_G11F_B10F | Clouds (RG) / Bloom (RGB)                                     |
| colortex5 | RGBA16F        | TAA (RGB) / Previous frame (RGB), Auto exposure (A)           |

## Custom Defined Macros
   This shader uses custom defined macros in every program and .glsl file for each world folders all connected to the main programs in the main folder. This is to keep the workflow minimized and understandable, and to identify what folder/program the shader is being used.

### Dimension Macros
   Found in all world.glsl files. Dimension macros define the world's lighting properties. These are not finalized and are still a work in progress as they tend to be inconsistent thus the reason of it being not available to the common user.

| Dimension Macros    | Type    | Usage                   |
| ------------------- | ------- | ----------------------- |
| WORLD_ID            | int     | World ID                |
| WORLD_LIGHT         | defined | World enabled shadows   |
| WORLD_SUN_MOON      | int     | World light source type |
| WORLD_SUN_MOON_SIZE | float   | World light source size |

### Program Macros
   Found in their respective programs in .fsh and .vsh files. The following are the listed common program macros. These macros typically only defines the program.

| Program Macros  | Type    |
| --------------- | ------- |
| SHADOW          | defined |
| GBUFFERS        | defined |
| DEFERRED        | defined |
| DEFERRED(1-99)  | defined |
| COMPOSITE       | defined |
| COMPOSITE(1-99) | defined |
| FINAL           | defined |

This along with the `GBUFFERS` macro, are used to identify the quirks in the current program for the shader to detect.

### Complex Programs
   List of programs with complex lighting. Common complex processes are in these programs. They compute complex processes such as PBR and vertex displacement for animations and tend to be very expensive.

| Program Macros   | Type    |
| ---------------- | ------- |
| TERRAIN          | defined |
| WATER            | defined |
| BLOCK            | defined |
| ENTITIES_GLOWING | defined |
| ENTITIES         | defined |
| HAND             | defined |
| HAND_WATER       | defined |

### Basic Programs
   List of programs with basic lighting. Common basic processes are in these programs. They compute basic processes that complex programs have, but with removed features that the program doesn't necessarily need.

| Program Macros | Type    |
| -------------- | ------- |
| BASIC          | defined |
| CLOUDS         | defined |
| TEXTURED       | defined |

### Simple programs
   List of programs with simpler shading. Common simple processes are in these programs. As the name suggests, they compute very simple and fast processes. The reason is usually because they don't need additional features as they tend to slow GPU performance.

| Program Macros | Type    |
| -------------- | ------- |
| ARMOR_GLINT    | defined |
| BEACON_BEAM    | defined |
| SPIDER_EYES    | defined |
| DAMAGED_BLOCK  | defined |
| WEATHER        | defined |
| SKY_TEXTURED   | defined |
| LINE           | defined |

### Disabled programs
   List of discarded and disabled programs. They typically have no other purposes other than disabling a program by using `discard;` + `return;`. This method is used to conveniently disable programs without using `shaders.properties` to disable the program per world.

| Program Macros | Type    |
| -------------- | ------- |
| SKY_BASIC      | defined |

## TO DO (for Eldeston)
* Refactor uniform usage and remove unecessary ones
* Optimize DOF calculations with noise
* Create a custom shadow model view
* Fix transparency issues with CTM
* Optimize albedo alpha testing
* Fix glint z fighting

* Optimize block ids in block.properties
* Document the shader pipeline

* Implement cloud absorption
* Improve water absorption