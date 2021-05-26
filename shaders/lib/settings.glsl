// #define VIGNETTE // Enable vignette
#define VIGNETTE_INTENSITY 1 // Vignette intensity in powers (vignette ^ VIGNETTE_INTENSITY) [1 2 3 4 5]

// Shadow distortion factor
#define SHADOW_DISTORT_FACTOR 0.06
#define RENDER_FOLIAGE_SHD // Enable foliage shadow render

// Off by default
// #define WHITE_MODE // Enable white mode/textureless mode, keeps materials
// #define WHITE_MODE_F // Enable white mode with foliage colors (if WHITE_MODE is on)

#define AUTO_EXPOSURE // Auto exposure, can be potentionally buggy in certain situations

#define SATURATION 1.4 // Saturation [0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0 1.05 1.1 1.15 1.2 1.25 1.3 1.35 1.4 1.45 1.5 1.55 1.6 1.65 1.7 1.75 1.8 1.85 1.9 1.95 2.0]
#define EXPOSURE 1.0 // Exposure [0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0 1.05 1.1 1.15 1.2 1.25 1.3 1.35 1.4 1.45 1.5 1.55 1.6 1.65 1.7 1.75 1.8 1.85 1.9 1.95 2.0]
#define CONTRAST 1.2 // Contrast [0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0 1.05 1.1 1.15 1.2 1.25 1.3 1.35 1.4 1.45 1.5 1.55 1.6 1.65 1.7 1.75 1.8 1.85 1.9 1.95 2.0]
#define GAMMA 1.0 // Gamma [0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0 1.05 1.1 1.15 1.2 1.25 1.3 1.35 1.4 1.45 1.5 1.55 1.6 1.65 1.7 1.75 1.8 1.85 1.9 1.95 2.0]

#define BLOOM // Enable emission based bloom
#define BLOOM_LOD 2.0 // Bloom lod amount, increase this if your monitor is big and the bloom blur is small [1.0 2.0 3.0 4.0 5.0 6.0 7.0 8.0 9.0 10.0]
#define BLOOM_PIX_SIZE 2.0 // Bloom pixel size, you may increase this along with bloom lod [1.0 2.0 4.0 8.0 16.0]
#define BLOOM_BRIGHTNESS 0.8 // Bloom brightness [0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]
#define BLOOM_QUALITY 1 // Increase it to 2 for better quality bloom. May use more performance! [1 2]

#define WATER_BLUR_SIZE 8.0 // Water blur size, the smaller the sharper the waves look, the larger the smoother the waves look [1.0 2.0 4.0 8.0 12.0 16.0 32.0]
#define WATER_DEPTH_SIZE 16 // The depth amount of the water, the smaller the more deeper it looks [4 8 12 16 20]
#define WATER_TILE_SIZE 24 // Tile size of the water [8 16 24 32 40 48 56 64 72 80]
#define INVERSE // Inverses the heightmap of the water normals which is more realistic

#define SHADOW_FILTER // Enable soft shadow filtering, if enabled shadows will appear softer, this costs performance
#define SHD_COL // Enable shadow color from colored transparent objects

// #define SSGI // Enables SSGI, currently experimental and may not be very optimized, may improve the ambience of dark areas despite the noisiness
#define SSGI_STEPS 16 // SSGI steps, more steps means more quality, and more quality means more performance [16 20 24 28 32]
#define SSGI_BISTEPS 0 // SSGI binary refinement steps, more steps means more accurate GI, and more quality means more performance [0 4 8 16]

#define SSR // Enables SSR, may not look good in certain areas
#define SSR_STEPS 24 // SSR steps, more steps means more quality, and more quality means more performance [16 20 24 28 32]
#define SSR_BISTEPS 4 // SSR binary refinement steps, more steps means more accurate reflections, and more quality means more performance [0 4 8 16]

// #define TEMPORAL_ACCUMULATION // Reduces the amount of noise by temporal acumulation, currently experimental.
#define ACCUMILATION_SPEED 4.0 // The fade speed of temporal accumulation. The higher the faster [1.0 2.0 4.0 8.0 16.0]

#define DEFAULT_MAT // Enable inbuilt default PBR materials(emissiveMap, speculars, subsurface scaterring etc.). Disable to use your PBR resource packs. Latest LabPBR version required!
#define NOISE_SPEED 1.0 // The speed in which the noise randomises each frame. Set it zero if you want the noise to be constant each frame [0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]
#define BUFFER_VIEW gcolor // Views buffers. colortex1 views normals(in 0-1 range, view space), colortex2 views lightmap and subsurface scattering material, colortex3-4 are the rest of the materials, colortex5 for reflection buffer, colortex6 for exposure buffer and colortex7 remains unused will output a black screen. [gcolor colortex1 colortex2 colortex3 colortex4 colortex5 colortex6 colortex7]

#define VOL_LIGHT_BRIGHTNESS 0.5 // The brightness/amount of volumetric lighting, set it to zero to disable it [0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]
#define MIST_GROUND_FOG_BRIGHTNESS 0.8 // The brightness/amount of mist/ground fog, set it to zero to disable it [0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]

/*---------------------------------------------------------------------------------------------------------------------------*/

#define LIGHT_COL_DAY vec3(2.0, 1.9, 1.8)
#define LIGHT_COL_NIGHT vec3(0.1, 0.2, 0.3)
#define LIGHT_COL_DAWN_DUSK vec3(1.2, 0.9, 0.3)

#define SKY_COL_DAY vec3(0.6, 0.8, 1)
#define SKY_COL_NIGHT vec3(0.05, 0.1, 0.2)
#define SKY_COL_DAWN_DUSK vec3(0.24, 0.08, 0.24)

#define BLOCK_LIGHT_COL vec3(1, 0.9, 0.8)