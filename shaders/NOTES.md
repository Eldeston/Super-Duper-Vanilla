## Standards
   These standards are kept in order to keep the code consistent and readable.
* Minimize resources and maximize performance.
* Keep the code squeaky clean, understandable, and portable.

## Used Framebuffers
   Current shader pipeline uses 6 framebuffers to minimize resources used and maximize performance.
* gcolor - Main scene / Skybox, vanilla sun and moon : R11F_G11F_B10F
* colortex1 - Normals : RGB16_SNORM
* colortex2 - Raw albedo, SSAO : RGBA8
* colortex3 - Metallic, roughness, glowing entity / Final output : RGB8
* colortex4 - Clouds / Bloom : R11F_G11F_B10F
* colortex5 - TAA / Previous reflections, Auto exposure : RGBA16F

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
   Programs with complex lighting.
* TERRAIN
* WATER
* BLOCK
* ENTITIES_GLOWING
* ENTITIES
* HAND
* HAND_WATER

### Simple Programs
   Programs with basic lighting.
* BASIC
* CLOUDS
* TEXTURED

### Basic programs
   Programs with simple shading.
* ARMOR_GLINT
* BEACON_BEAM
* SPIDER_EYES
* DAMAGED_BLOCK
* WEATHER

* LINE
* SKY_BASIC
* SKY_TEXTURED
