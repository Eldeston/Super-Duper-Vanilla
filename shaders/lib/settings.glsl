/// -------------------------------- /// Post /// -------------------------------- ///

#define OUTLINES 2 // Enables outlines. Set to standard for classic outlined blocks, or Dungeons for Dungeons/SDGP styled outlines. [0 1 2]
#define OUTLINE_BRIGHTNESS 1.00 // Outline brightness. Set it to -1 for black outlines, or 1 to highlighted outlines. [-1.00 -0.95 -0.90 -0.85 -0.80 -0.75 -0.70 -0.65 -0.60 -0.55 -0.50 -0.45 -0.40 -0.35 -0.30 -0.25 -0.20 -0.15 -0.10 -0.05 0.00 0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00]
#define OUTLINE_PIX_SIZE 1 // Outline pixel size. Adjust to change the thickness of the outlines [1 2 4 8 16 32 64]

// #define RETRO_FILTER // Enable retro filter. Works best at low render quality.

#define ANTI_ALIASING 2 // Enables anti-aliasing. FXAA is fast and works with screenshot sizes. TAA is slower, doesn't work with custom screenshots, but smooths noise. Disable anti-aliasing on your shader menu before using this feature! [0 1 2 3]
// #define SHARPEN_FILTER // Enables image sharpening. Use this with AA on if the image appears blurry.

/// -------------------------------- /// Camera /// -------------------------------- ///

// #define DOF // Enables depth of field. Enables anti-aliasing for better results.
#define DOF_STRENGTH 2 // Depth of field strength. [1 2 4]

// #define CHROMATIC_ABERRATION // Enable chromatic abberation.
#define ABERRATION_PIX_SIZE 4 // Chromating abberation length. Increase for stronger effects. [1 2 4 8 16]

#define BLOOM // Enables bloom.
#define BLOOM_STRENGTH 0.20 // Bloom brightness [0.00 0.01 0.02 0.03 0.04 0.05 0.06 0.07 0.08 0.09 0.10 0.11 0.12 0.13 0.14 0.15 0.16 0.17 0.18 0.19 0.20 0.21 0.22 0.23 0.24 0.25 0.26 0.27 0.28 0.29 0.30 0.31 0.32 0.33 0.34 0.35 0.36 0.37 0.38 0.39 0.40 0.41 0.42 0.43 0.44 0.45 0.46 0.47 0.48 0.49 0.50]

#define LENS_FLARE // Enables lens flare.
#define LENS_FLARE_STRENGTH 1.00 // Lens flare intensity. [0.00 0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00 1.05 1.10 1.15 1.20 1.25 1.30 1.35 1.40 1.45 1.50 1.55 1.60 1.65 1.70 1.75 1.80 1.85 1.90 1.95 2.00]

// #define VIGNETTE // Enables vignette
#define VIGNETTE_STRENGTH 1.00 // Vignette intensity [0.00 0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00 1.05 1.10 1.15 1.20 1.25 1.30 1.35 1.40 1.45 1.50 1.55 1.60 1.65 1.70 1.75 1.80 1.85 1.90 1.95 2.00]

// #define MOTION_BLUR // Enable motion blur.
#define MOTION_BLUR_STRENGTH 1.00 // Motion blur strength. [0.00 0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00 1.05 1.10 1.15 1.20 1.25 1.30 1.35 1.40 1.45 1.50 1.55 1.60 1.65 1.70 1.75 1.80 1.85 1.90 1.95 2.00]

/// -------------------------------- /// Tonemapping /// -------------------------------- ///

#define CONTRAST 1.00 // Contrast, controls color contrast [0.00 0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00 1.05 1.10 1.15 1.20 1.25 1.30 1.35 1.40 1.45 1.50 1.55 1.60 1.65 1.70 1.75 1.80 1.85 1.90 1.95 2.00]
#define SATURATION 1.00 // Saturation, controls how much color saturation [0.00 0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00 1.05 1.10 1.15 1.20 1.25 1.30 1.35 1.40 1.45 1.50 1.55 1.60 1.65 1.70 1.75 1.80 1.85 1.90 1.95 2.00]

#define WHITE_POINT 2.0 // Tonemap whitepoint [0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0 2.1 2.2 2.3 2.4 2.5 2.6 2.7 2.8 2.9 3.0 3.1 3.2 3.3 3.4 3.5 3.6 3.7 3.8 3.9 4.0]
#define SHOULDER_STRENGTH 0.00 // Tonemap shoulder strength [0.00 0.01 0.02 0.03 0.04 0.05 0.06 0.07 0.08 0.09 0.10 0.11 0.12 0.13 0.14 0.15 0.16 0.17 0.18 0.19 0.20 0.21 0.22 0.23 0.24 0.25 0.26 0.27 0.28 0.29 0.30 0.31 0.32 0.33 0.34 0.35 0.36 0.37 0.38 0.39 0.40 0.41 0.42 0.43 0.44 0.45 0.46 0.47 0.48 0.49 0.50 0.51 0.52 0.53 0.54 0.55 0.56 0.57 0.58 0.59 0.60 0.61 0.62 0.63 0.64 0.65 0.66 0.67 0.68 0.69 0.70 0.71 0.72 0.73 0.74 0.75 0.76 0.77 0.78 0.79 0.80 0.81 0.82 0.83 0.84 0.85 0.86 0.87 0.88 0.89 0.90 0.91 0.92 0.93 0.94 0.95 0.96 0.97 0.98 0.99 1.00]

// #define AUTO_EXPOSURE // Enables real time auto exposure. Does not work with custom Optifine screenshot resolutions!
#define AUTO_EXPOSURE_SPEED 1.00 // Auto exposure temporal speed. Changes how fast or slow the auto exposure will adjust to the screen's exposure. Smaller values means slower, bigger values means faster. [0.00 0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00 1.05 1.10 1.15 1.20 1.25 1.30 1.35 1.40 1.45 1.50 1.55 1.60 1.65 1.70 1.75 1.80 1.85 1.90 1.95 2.00]
#define EXPOSURE 1.00 // Exposure, controls color exposure [0.00 0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00 1.05 1.10 1.15 1.20 1.25 1.30 1.35 1.40 1.45 1.50 1.55 1.60 1.65 1.70 1.75 1.80 1.85 1.90 1.95 2.00]
#define MIN_EXPOSURE 0.10 // Min auto exposure value. Lower values may increase exposure of dark scenes if auto exposure is on. [0.10 0.20 0.30 0.40 0.50 0.60 0.70 0.80 0.90]

#define TINT_R 255 // Red tint value [3 6 9 12 15 18 21 24 27 30 33 36 39 42 45 48 51 54 57 60 63 66 69 72 75 78 81 84 87 90 93 96 99 102 105 108 111 114 117 120 123 126 129 132 135 138 141 144 147 150 153 156 159 162 165 168 171 174 177 180 183 186 189 192 195 198 201 204 207 210 213 216 219 222 225 228 231 234 237 240 243 246 249 252 255]
#define TINT_G 255 // Red tint value value [3 6 9 12 15 18 21 24 27 30 33 36 39 42 45 48 51 54 57 60 63 66 69 72 75 78 81 84 87 90 93 96 99 102 105 108 111 114 117 120 123 126 129 132 135 138 141 144 147 150 153 156 159 162 165 168 171 174 177 180 183 186 189 192 195 198 201 204 207 210 213 216 219 222 225 228 231 234 237 240 243 246 249 252 255]
#define TINT_B 255 // Red tint value value [3 6 9 12 15 18 21 24 27 30 33 36 39 42 45 48 51 54 57 60 63 66 69 72 75 78 81 84 87 90 93 96 99 102 105 108 111 114 117 120 123 126 129 132 135 138 141 144 147 150 153 156 159 162 165 168 171 174 177 180 183 186 189 192 195 198 201 204 207 210 213 216 219 222 225 228 231 234 237 240 243 246 249 252 255]

/// -------------------------------- /// Lighting /// -------------------------------- ///

#define SHADOW_MAPPING // Enables shadow mapping. Disable to use fake shadows with lightmap.
#define SHADOW_FILTER // Enables soft shadow filtering, if enabled shadows will appear softer by using noise. May impact performance.
#define SHADOW_COLOR // Enables shadow color from colored transparent objects.

#define ENTITY_SHADOWS // Enables entity shadows.
#define BLOCK_ENTITY_SHADOWS // Enables block entity shadows.

const float sunPathRotation = 30.0; // Light path angle. This also affects sky angle. [-60.0 -55.0 -50.0 -45.0 -40.0 -35.0 -30.0 -25.0 -20.0 -15.0 -10.0 -5.0 0.0 5.0 10.0 15.0 20.0 25.0 30.0 35.0 40.0 45.0 50.0 55.0 60.0]

#define UNDERWATER_CAUSTICS 1 // Enables underwater caustics. Shadow color must be enabled! [0 1 2]
#define SSAO // Enables screenspace ambient occlusion.
#define AMBIENT_LIGHTING 0.05 // Overall ambient lighting value. Increase if you dislike the pitch black darkness, higher values may make lighting unrealistic. Set it to zero for a more realistic approach if you have SSGI enabled. Set it to 0.50 for nightvision. [0.00 0.01 0.02 0.03 0.04 0.05 0.06 0.07 0.08 0.09 0.10 0.11 0.12 0.13 0.14 0.15 0.16 0.17 0.18 0.19 0.20 0.21 0.22 0.23 0.24 0.25 0.26 0.27 0.28 0.29 0.30 0.31 0.32 0.33 0.34 0.35 0.36 0.37 0.38 0.39 0.40 0.41 0.42 0.43 0.44 0.45 0.46 0.47 0.48 0.49 0.50]

/// -------------------------------- /// Ray traing settings /// -------------------------------- ///

// #define SSGI // Enables SSGI, currently experimental and may not be very optimized, may improve the ambience of dark areas despite the noisiness. Turn on TAA for best results.
#define SSGI_STEPS 20 // SSGI steps, increasing may improve quality but demand more performance [16 20 24 28 32]
#define SSGI_BISTEPS 4 // SSGI binary refinement steps, improves quality especially when using a low step count, balancing the values is required for optimum performance [0 4 8 16]

#define SSR // Enables SSR, may not look good in certain areas
#define SSR_STEPS 20 // SSR steps, increasing may improve quality but demand more performance [16 20 24 28 32]
#define SSR_BISTEPS 4 // SSR binary refinement steps, improves quality especially when using a low step count, balancing the values is required for optimum performance [0 4 8 16]

// #define ROUGH_REFLECTIONS // Enables rougher objects to have rougher reflections. May show weird artifacts, but some AA might fix it.
// #define PREVIOUS_FRAME // Reads previous frame buffer colors alowing SSR or SSGI to have infinite bounces of light. Impacts performance!

/// -------------------------------- /// Atmospherics /// -------------------------------- ///

#define SUN_MOON_TYPE 0 // Sun and moon type [0 1 2]
#define SUN_MOON_INTENSITY 5 // The sun or moon's intensity. Also affects specular reflections. [2 3 4 5 6 7 8]

#define VOLUMETRIC_LIGHTING // Enables volumetric lighting.
#define VOLUMETRIC_LIGHTING_STRENGTH 0.50 // The strength of volumetric lighting, set it to zero to disable it [0.00 0.01 0.02 0.03 0.04 0.05 0.06 0.07 0.08 0.09 0.10 0.11 0.12 0.13 0.14 0.15 0.16 0.17 0.18 0.19 0.20 0.21 0.22 0.23 0.24 0.25 0.26 0.27 0.28 0.29 0.30 0.31 0.32 0.33 0.34 0.35 0.36 0.37 0.38 0.39 0.40 0.41 0.42 0.43 0.44 0.45 0.46 0.47 0.48 0.49 0.50 0.51 0.52 0.53 0.54 0.55 0.56 0.57 0.58 0.59 0.60 0.61 0.62 0.63 0.64 0.65 0.66 0.67 0.68 0.69 0.70 0.71 0.72 0.73 0.74 0.75 0.76 0.77 0.78 0.79 0.80 0.81 0.82 0.83 0.84 0.85 0.86 0.87 0.88 0.89 0.90 0.91 0.92 0.93 0.94 0.95 0.96 0.97 0.98 0.99 1.00]
#define BORDER_FOG // Enables border fog to cover world edges
#define GROUND_FOG_STRENGTH 0.50 // The strength of mist/ground fog. [0.00 0.01 0.02 0.03 0.04 0.05 0.06 0.07 0.08 0.09 0.10 0.11 0.12 0.13 0.14 0.15 0.16 0.17 0.18 0.19 0.20 0.21 0.22 0.23 0.24 0.25 0.26 0.27 0.28 0.29 0.30 0.31 0.32 0.33 0.34 0.35 0.36 0.37 0.38 0.39 0.40 0.41 0.42 0.43 0.44 0.45 0.46 0.47 0.48 0.49 0.50 0.51 0.52 0.53 0.54 0.55 0.56 0.57 0.58 0.59 0.60 0.61 0.62 0.63 0.64 0.65 0.66 0.67 0.68 0.69 0.70 0.71 0.72 0.73 0.74 0.75 0.76 0.77 0.78 0.79 0.80 0.81 0.82 0.83 0.84 0.85 0.86 0.87 0.88 0.89 0.90 0.91 0.92 0.93 0.94 0.95 0.96 0.97 0.98 0.99 1.00]

#define STORY_MODE_CLOUDS // Uses procedurally generated clouds (a.k.a. aerogel clouds) instead of vanilla clouds. Disable vanilla clouds for proper results.
// #define DOUBLE_VANILLA_CLOUDS // Adds another layer of vanilla clouds (does not apply to story mode clouds), may use up performance.
#define DYNAMIC_CLOUDS // Makes clouds more dynamic and allows weather to affect it. (affects on both vanilla and story mode clouds).
#define FADE_SPEED 0.20 // Cloud fade speed [0.00 0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00 1.05 1.10 1.15 1.20 1.25 1.30 1.35 1.40 1.45 1.50 1.55 1.60 1.65 1.70 1.75 1.80 1.85 1.90 1.95 2.00 2.05 2.10 2.15 2.20 2.25 2.30 2.35 2.40 2.45 2.50 2.55 2.60 2.65 2.70 2.75 2.80 2.85 2.90 2.95 3.00 3.05 3.10 3.15 3.20 3.25 3.30 3.35 3.40 3.45 3.50 3.55 3.60 3.65 3.70 3.75 3.80 3.85 3.90 3.95 4.00]
#define SECOND_CLOUD_HEIGHT 64.0 // 2nd layer cloud height, if double vanilla clouds is on [-128.0 -112.0 -96.0 -80.0 -64.0 -48.0 -32.0 -16.0 16.0 32.0 48.0 64.0 80.0 96.0 112.0 128.0]
#define SKYBOX_BRIGHTNESS 1.00 // Sky box brightness. [0.00 0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00 1.05 1.10 1.15 1.20 1.25 1.30 1.35 1.40 1.45 1.50 1.55 1.60 1.65 1.70 1.75 1.80 1.85 1.90 1.95 2.00]

/// -------------------------------- /// World /// -------------------------------- ///

#define TERRAIN_ANIMATION // Enables terrain waving animation.
#define WATER_ANIMATION // Enables water waving animation.
#define WEATHER_ANIMATION // Enables rain waving animation. 

#define TIMELAPSE_MODE 0 // Enable timelapse mode. This smoothens the transition of animations of the sky, the foliage waving etc according to current world time instead of frame time. Set to fragment for water normals and sky only and full for the water normals, sky, and waves. This feature does not work on vanilla clouds, skybox, and the sun and moon. [0 1 2]

#define WIND_SPEED 1.00 // Adjust wind speed. Affects plants, swinging objects, and weather. Increases the animation speed. [0.00 0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00 1.05 1.10 1.15 1.20 1.25 1.30 1.35 1.40 1.45 1.50 1.55 1.60 1.65 1.70 1.75 1.80 1.85 1.90 1.95 2.00 2.05 2.10 2.15 2.20 2.25 2.30 2.35 2.40 2.45 2.50 2.55 2.60 2.65 2.70 2.75 2.80 2.85 2.90 2.95 3.00 3.05 3.10 3.15 3.20 3.25 3.30 3.35 3.40 3.45 3.50 3.55 3.60 3.65 3.70 3.75 3.80 3.85 3.90 3.95 4.00]
#define CURRENT_SPEED 1.00 // Adjust liquid and under water flow speed. Affects underwater plants and liquids. Increases the animation speed. [0.00 0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00 1.05 1.10 1.15 1.20 1.25 1.30 1.35 1.40 1.45 1.50 1.55 1.60 1.65 1.70 1.75 1.80 1.85 1.90 1.95 2.00 2.05 2.10 2.15 2.20 2.25 2.30 2.35 2.40 2.45 2.50 2.55 2.60 2.65 2.70 2.75 2.80 2.85 2.90 2.95 3.00 3.05 3.10 3.15 3.20 3.25 3.30 3.35 3.40 3.45 3.50 3.55 3.60 3.65 3.70 3.75 3.80 3.85 3.90 3.95 4.00]

#define WIND_FREQUENCY 1.00 // Adjust wind frequency. Affects plants, swinging objects, and weather. Increases the animation change frequency. [0.00 0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00 1.05 1.10 1.15 1.20 1.25 1.30 1.35 1.40 1.45 1.50 1.55 1.60 1.65 1.70 1.75 1.80 1.85 1.90 1.95 2.00 2.05 2.10 2.15 2.20 2.25 2.30 2.35 2.40 2.45 2.50 2.55 2.60 2.65 2.70 2.75 2.80 2.85 2.90 2.95 3.00 3.05 3.10 3.15 3.20 3.25 3.30 3.35 3.40 3.45 3.50 3.55 3.60 3.65 3.70 3.75 3.80 3.85 3.90 3.95 4.00]
#define CURRENT_FREQUENCY 1.00 // Adjust liquid and under water flow frequency. Affects underwater plants and liquids. Increases the animation change frequency. [0.00 0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00 1.05 1.10 1.15 1.20 1.25 1.30 1.35 1.40 1.45 1.50 1.55 1.60 1.65 1.70 1.75 1.80 1.85 1.90 1.95 2.00 2.05 2.10 2.15 2.20 2.25 2.30 2.35 2.40 2.45 2.50 2.55 2.60 2.65 2.70 2.75 2.80 2.85 2.90 2.95 3.00 3.05 3.10 3.15 3.20 3.25 3.30 3.35 3.40 3.45 3.50 3.55 3.60 3.65 3.70 3.75 3.80 3.85 3.90 3.95 4.00]

// #define WORLD_CURVATURE // Enable world curvature
#define WORLD_CURVATURE_SIZE 256 // World curvature size [-4096 -2048 -1024 -512 -256 -128 128 256 512 1024 2048 4096]

/// -------------------------------- /// PBR /// -------------------------------- ///

#define PBR_MODE 1 // Enables PBR. Integrated PBR depends on the vanilla albedo textures to map out the materials. Resource PBR uses your resource packs' PBR, if available. Resource PBR requires latest LabPBR version! [0 1 2]
#define ENVIRO_PBR // Enables enviroment materials. Environment materials affects your surrounding according to your environment such as rain.
// #define AUTO_GEN_NORM // Enables auto generated normals. Works if Integrated PBR is on. Works mostly on vanilla resource packs.
#define AUTO_GEN_NORM_RES 128 // Auto generated normal resolution. Minor effects to performance. [16 32 64 128 256 512 1024]
#define SUBSURFACE_SCATTERING // Enables subsurface scattering. 

#define EMISSIVE_INTENSITY 8 // Emissive maps intensity. Does not affect lightmaps and requires PBR on. [2 4 8 16 32]
// #define SLOPE_NORMALS // Enables slope normals. Disable this feature if you're using a high resolution pack with normal maps. Thanks @Null!
#define NORMAL_STRENGTH 1.00 // Normal map strength. Effective only if PBR is on with the RP normals, and slope normals is off. [0.00 0.01 0.02 0.03 0.04 0.05 0.06 0.07 0.08 0.09 0.10 0.11 0.12 0.13 0.14 0.15 0.16 0.17 0.18 0.19 0.20 0.21 0.22 0.23 0.24 0.25 0.26 0.27 0.28 0.29 0.30 0.31 0.32 0.33 0.34 0.35 0.36 0.37 0.38 0.39 0.40 0.41 0.42 0.43 0.44 0.45 0.46 0.47 0.48 0.49 0.50 0.51 0.52 0.53 0.54 0.55 0.56 0.57 0.58 0.59 0.60 0.61 0.62 0.63 0.64 0.65 0.66 0.67 0.68 0.69 0.70 0.71 0.72 0.73 0.74 0.75 0.76 0.77 0.78 0.79 0.80 0.81 0.82 0.83 0.84 0.85 0.86 0.87 0.88 0.89 0.90 0.91 0.92 0.93 0.94 0.95 0.96 0.97 0.98 0.99 1.00]
// #define DIRECTIONAL_LIGHTMAPS // Enables directional lightmaps. Effective only if auto generated normals or normal maps from PBR is enabled.
#define DIRECTIONAL_LIGHTMAP_STRENGTH 1.00 // Directional lightmap strength. Effective if directional lightmaps is enabled. [0.00 0.01 0.02 0.03 0.04 0.05 0.06 0.07 0.08 0.09 0.10 0.11 0.12 0.13 0.14 0.15 0.16 0.17 0.18 0.19 0.20 0.21 0.22 0.23 0.24 0.25 0.26 0.27 0.28 0.29 0.30 0.31 0.32 0.33 0.34 0.35 0.36 0.37 0.38 0.39 0.40 0.41 0.42 0.43 0.44 0.45 0.46 0.47 0.48 0.49 0.50 0.51 0.52 0.53 0.54 0.55 0.56 0.57 0.58 0.59 0.60 0.61 0.62 0.63 0.64 0.65 0.66 0.67 0.68 0.69 0.70 0.71 0.72 0.73 0.74 0.75 0.76 0.77 0.78 0.79 0.80 0.81 0.82 0.83 0.84 0.85 0.86 0.87 0.88 0.89 0.90 0.91 0.92 0.93 0.94 0.95 0.96 0.97 0.98 0.99 1.00]

/// -------------------------------- /// Water material settings /// -------------------------------- ///

#define WATER_NOISE // Enables water noise. Varies the water brightness by noise similar to SDGP.
#define WATER_BRIGHTNESS 1.00 // Water brightness, lower values mean deeper colors [0.00 0.01 0.02 0.03 0.04 0.05 0.06 0.07 0.08 0.09 0.10 0.11 0.12 0.13 0.14 0.15 0.16 0.17 0.18 0.19 0.20 0.21 0.22 0.23 0.24 0.25 0.26 0.27 0.28 0.29 0.30 0.31 0.32 0.33 0.34 0.35 0.36 0.37 0.38 0.39 0.40 0.41 0.42 0.43 0.44 0.45 0.46 0.47 0.48 0.49 0.50 0.51 0.52 0.53 0.54 0.55 0.56 0.57 0.58 0.59 0.60 0.61 0.62 0.63 0.64 0.65 0.66 0.67 0.68 0.69 0.70 0.71 0.72 0.73 0.74 0.75 0.76 0.77 0.78 0.79 0.80 0.81 0.82 0.83 0.84 0.85 0.86 0.87 0.88 0.89 0.90 0.91 0.92 0.93 0.94 0.95 0.96 0.97 0.98 0.99 1.00]

#define WATER_NORM // Enables water normals
#define WATER_BLUR_SIZE 8.0 // Water normal map blur size, smaller means more defined waves, larger means smoother waves [1.0 2.0 4.0 8.0 16.0 32.0 64.0]
#define WATER_DEPTH_SIZE 0.5 // The normal map depth of the waves, the smaller the more depth it has [0.125 0.25 0.5 1.0 2.0]
#define WATER_TILE_SIZE 16 // Tile size of the water [4 8 16 24 32]

#define WATER_STYLIZE_ABSORPTION // Enables stylized water absorption. Changes water color based on depth.
#define WATER_FOAM // Enables water foam. Appears on the sides of most solid objects, including entities.
// #define WATER_FLAT // Enables flat water albedo.

/// -------------------------------- /// Lava material settings /// -------------------------------- ///

#define LAVA_BRIGHTNESS 1.00 // Lava brightness, lower values mean darker colors [0.00 0.01 0.02 0.03 0.04 0.05 0.06 0.07 0.08 0.09 0.10 0.11 0.12 0.13 0.14 0.15 0.16 0.17 0.18 0.19 0.20 0.21 0.22 0.23 0.24 0.25 0.26 0.27 0.28 0.29 0.30 0.31 0.32 0.33 0.34 0.35 0.36 0.37 0.38 0.39 0.40 0.41 0.42 0.43 0.44 0.45 0.46 0.47 0.48 0.49 0.50 0.51 0.52 0.53 0.54 0.55 0.56 0.57 0.58 0.59 0.60 0.61 0.62 0.63 0.64 0.65 0.66 0.67 0.68 0.69 0.70 0.71 0.72 0.73 0.74 0.75 0.76 0.77 0.78 0.79 0.80 0.81 0.82 0.83 0.84 0.85 0.86 0.87 0.88 0.89 0.90 0.91 0.92 0.93 0.94 0.95 0.96 0.97 0.98 0.99 1.00]
#define LAVA_NOISE // Enables lava noise. Varies the lava brightness by noise similar to Minecraft Dungeons.
#define LAVA_TILE_SIZE 16 // Tile size of the lava [4 8 16 24 32]

/// -------------------------------- /// Parallax occlussion settings /// -------------------------------- ///

// #define PARALLAX_OCCLUSION // Enables parallax occlusion. Requires LabPBR on and a resource pack with LabPBR enabled materials.
#define PARALLAX_DEPTH 0.25 // Parallax occlusion depth strength. Increase for more depth. [0.00 0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50]
#define PARALLAX_STEPS 128 // Parallax occlusion step ammount. Increase for improved POM quality. [16 32 64 128 256 512]

#define PARALLAX_SHADOWS // Enables parallax self shadowing.
#define PARALLAX_SHADOW_STEPS 32 // Parallax self shadowing step ammount. Increase for improved self shadowing quality. [16 32 64 128 256 512]

/// -------------------------------- /// Configuration /// -------------------------------- ///

#define BLOCKLIGHT_R 255 // Red value [3 6 9 12 15 18 21 24 27 30 33 36 39 42 45 48 51 54 57 60 63 66 69 72 75 78 81 84 87 90 93 96 99 102 105 108 111 114 117 120 123 126 129 132 135 138 141 144 147 150 153 156 159 162 165 168 171 174 177 180 183 186 189 192 195 198 201 204 207 210 213 216 219 222 225 228 231 234 237 240 243 246 249 252 255]
#define BLOCKLIGHT_G 240 // Green value [3 6 9 12 15 18 21 24 27 30 33 36 39 42 45 48 51 54 57 60 63 66 69 72 75 78 81 84 87 90 93 96 99 102 105 108 111 114 117 120 123 126 129 132 135 138 141 144 147 150 153 156 159 162 165 168 171 174 177 180 183 186 189 192 195 198 201 204 207 210 213 216 219 222 225 228 231 234 237 240 243 246 249 252 255]
#define BLOCKLIGHT_B 210 // Blue value [3 6 9 12 15 18 21 24 27 30 33 36 39 42 45 48 51 54 57 60 63 66 69 72 75 78 81 84 87 90 93 96 99 102 105 108 111 114 117 120 123 126 129 132 135 138 141 144 147 150 153 156 159 162 165 168 171 174 177 180 183 186 189 192 195 198 201 204 207 210 213 216 219 222 225 228 231 234 237 240 243 246 249 252 255]
#define BLOCKLIGHT_I 1.00 // Intensity value [0.00 0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00 1.05 1.10 1.15 1.20 1.25 1.30 1.35 1.40 1.45 1.50 1.55 1.60 1.65 1.70 1.75 1.80 1.85 1.90 1.95 2.00]
const vec3 blockLightCol = vec3(BLOCKLIGHT_R, BLOCKLIGHT_G, BLOCKLIGHT_B) * (BLOCKLIGHT_I * 0.00392156863);

/// -------------------------------- /// Secret settings /// -------------------------------- ///

#define COLOR_MODE 0 // Albedo color mode. White mode makes everything white. Black mode makes everything black. Foliage mode shows only foliage colors. Keeps materials on. [0 1 2 3]
#define NOISE_SPEED 8 // The speed in which the noise randomises each frame. Useful for TAA. This effect is visible only when TAA is enabled. [2 4 8 16 32]

/// -------------------------------- /// Physics mod settings /// -------------------------------- ///

// Note to self: I absolutely want all of the variables below this text to be all macros to follow the style guideline

#define PHYSICS_OCEAN_SUPPORT // Enables physics mod ocean support

const int PHYSICS_ITERATIONS_OFFSET = 13;

const float PHYSICS_DRAG_MULT = 0.048;
const float PHYSICS_XZ_SCALE = 0.035;
const float PHYSICS_TIME_MULTIPLICATOR = 0.45;
const float PHYSICS_W_DETAIL = 0.75;
const float PHYSICS_FREQUENCY = 6.0;
const float PHYSICS_SPEED = 2.0;
const float PHYSICS_WEIGHT = 0.8;
const float PHYSICS_FREQUENCY_MULT = 1.18;
const float PHYSICS_SPEED_MULT = 1.07;
const float PHYSICS_ITER_INC = 12.0;
const float PHYSICS_NORMAL_STRENGTH = 0.6;

/// -------------------------------- /// Misc /// -------------------------------- ///

// For the shader loaders to detect the "phantom" options
#ifdef ENTITY_SHADOWS
#endif

#ifdef BLOCK_ENTITY_SHADOWS
#endif

#ifdef VOLUMETRIC_LIGHTING
#endif

#ifdef STORY_MODE_CLOUDS
#endif

#ifdef ENVIRO_PBR
#endif

#ifdef AUTO_GEN_NORM
#endif

#ifdef DIRECTIONAL_LIGHTMAPS
#endif

#ifdef PARALLAX_SHADOWS
#endif