## Standards
   These standards must be kept in order to keep the code format consistent and readable.
* Minimize resources and maximize performance.
* Keep the code squeaky clean, understandable, and portable.

## GLSL Version
   The shader version used for this pipeline is **GLSL 3.3**. For more information see this [documentation provided by Khronos](https://registry.khronos.org/OpenGL/specs/gl/GLSLangSpec.3.30.pdf).

## Used Buffers
   Current shader pipeline uses 6 framebuffers to minimize resources used and maximize performance. Their usages are listed in order of what's written first.

| Buffers   | Format         | Usage                                                 |
| --------- | -------------- | ----------------------------------------------------- |
| gcolor    | R11F_G11F_B10F | Main HDR / Skybox, vanilla sun and moon               |
| colortex1 | RGB16_SNORM    | Normals                                               |
| colortex2 | RGBA8          | Albedo, SSAO                                          |
| colortex3 | RGB8           | Metallic, roughness, glowing entity / Main LDR / FXAA |
| colortex4 | R11F_G11F_B10F | Clouds / Bloom                                        |
| colortex5 | RGBA16F        | TAA / Previous reflections, Auto exposure             |

## Custom Defined Macros
   This shader uses custom defined macros in every program and .glsl file for each world folders all connected to the main programs in the main folder. This is to keep the workflow minimized and understandable, and to identify what folder/program the shader is being used.

### Dimension Macros
   Found in world.glsl files. These macros are used to identify the quirks in the current dimension folder for the shader to detect.
* WORLD_ID

### Program Macros
   Found in their respective programs in .fsh and .vsh files.
* SHADOW
* GBUFFERS
* DEFERRED
* DEFERRED(1-7)
* COMPOSITE
* COMPOSITE(1-7)
* FINAL

### Gbuffer Macros
   This along with the `GBUFFERS` macro, are used to identify the quirks in the current program for the shader to detect.

### Complex Programs
   List of programs with complex lighting. Common complex processes are in these programs.
* TERRAIN
* WATER
* BLOCK
* ENTITIES_GLOWING
* ENTITIES
* HAND
* HAND_WATER

### Simple Programs
   List of programs with basic lighting. Common basic processes are in these programs.
* BASIC
* CLOUDS
* TEXTURED

### Basic programs
   List of programs with simpler shading. Common simple processes are in these programs.
* ARMOR_GLINT
* BEACON_BEAM
* SPIDER_EYES
* DAMAGED_BLOCK
* WEATHER

* SKY_TEXTURED

* LINE

### Disabled programs
   List of discarded and disabled programs.
* SKY_BASIC

## TO DO (for Eldeston)
* Create a generic function for orthographic and perspective projection matrices
* Refactor uniform usage and remove unecessary ones
* Document the shader pipeline