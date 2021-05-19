// #define VIGNETTE // Enable vignette
#define VIGNETTE_INTENSITY 1 // Vignette intensity in powers (vignette ^ VIGNETTE_INTENSITY) [1 2 3 4 5]

// Shadow distortion factor
#define SHADOW_DISTORT_FACTOR 0.06
// #define SHD_SHARPNESS 1.0 // Shadow sharpness [1.0 1.25 1.5 1.75 2.0 2.25 2.5 2.75 3.0]
#define RENDER_FOLIAGE_SHD // Enable foliage shadow render

// Off by default
// #define WHITE_MODE // Enable white mode, reveals ao
// #define WHITE_MODE_F // Enable white mode with foliage colors (if WHITE_MODE is on)

#define BLOOM // Enable bloom
// #define FAST_BLOOM // Fast bloom with increased LOD, but uses a constant sample amount. May cause certain artifacts!
#define BLOOM_BRIGHTNESS 0.6 // Bloom brghtness [0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]
#define BLOOM_AMOUNT 0.8 // Bloom amount. Must not go below the threshold amount! [0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]
#define BLOOM_THRESHOLD 0.6 // Bloom threshold. Must not go above the bloom amount! [0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9]
#define BLOOM_SIZE 8.0 // Bloom size, may need to increase sample amount as the size increases [4.0 5.0 6.0 7.0 8.0 9.0 10.0 11.0 12.0 13.0 14.0 15.0 16.0]
#define BLOOM_SAMPLES 6 // Bloom blur samples, affects the quality of the blur. Does not affect if fast bloom is on! [8 10 12 14 16 18 20 22 24 26 28 30 32]

#define UNDERWATER_BLUR // Enable underwater blur
// #define FAST_UNDERWATER_BLUR // Fast underwater blur with increased LOD, but uses a constant sample amount. May cause certain artifacts!
#define UNDERWATER_BLUR_SIZE 8.0 // Underwater blur size, may need to increase sample amount as the size increases [4.0 5.0 6.0 7.0 8.0 9.0 10.0 11.0 12.0 13.0 14.0 15.0 16.0]
#define UNDERWATER_BLUR_SAMPLES 6 // Underwater blur samples, affects the quality of the blur. Does not affect if fast underwater blur is on! [8 10 12 14 16 18 20 22 24 26 28 30 32]

#define AUTO_EXPOSURE // Auto exposure, can be potentionally buggy in certain situations

/*
#define UNDERWATER_DISTORTION // Distorts view when underwater
#define DISTORT_AMOUNT 0.004 // Distortion amount [0.0005 0.001 0.0015 0.002 0.0025 0.003 0.0035 0.004 0.0045 0.005 0.0055 0.006 0.0065 0.007 0.0075 0.008 0.0085 0.009 0.0095 0.01]
#define DISTORT_SPEED 2.0 // Distortion speed [1.0 2.0 3.0 4.0 5.0 6.0 7.0 8.0 9.0 10.0]
#define DISTORT_FREQUENCY 64.0 // Distortion frequency [1.0 2.0 4.0 8.0 16.0 32.0 64.0 128.0 256.0]
*/

#define SATURATION 1.4 // Saturation [0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0 1.05 1.1 1.15 1.2 1.25 1.3 1.35 1.4 1.45 1.5 1.55 1.6 1.65 1.7 1.75 1.8 1.85 1.9 1.95 2.0]
#define EXPOSURE 1.0 // Exposure [0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0 1.05 1.1 1.15 1.2 1.25 1.3 1.35 1.4 1.45 1.5 1.55 1.6 1.65 1.7 1.75 1.8 1.85 1.9 1.95 2.0]
#define CONTRAST 1.1 // Contrast [0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0 1.05 1.1 1.15 1.2 1.25 1.3 1.35 1.4 1.45 1.5 1.55 1.6 1.65 1.7 1.75 1.8 1.85 1.9 1.95 2.0]
#define GAMMA 1.0 // Gamma [0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0 1.05 1.1 1.15 1.2 1.25 1.3 1.35 1.4 1.45 1.5 1.55 1.6 1.65 1.7 1.75 1.8 1.85 1.9 1.95 2.0]

#define WATER_BLUR_SIZE 8.0 // Water blur size, the smaller the sharper the waves look, the larger the smoother the waves look [1.0 2.0 4.0 8.0 12.0 16.0 32.0]
#define WATER_DEPTH_SIZE 16 // The depth amount of the water, the smaller the more deeper it looks [4 8 12 16 20]
#define WATER_TILE_SIZE 24 // Tile size of the water [8 16 24 32 40 48 56 64 72 80]
#define INVERSE // Inverses the heightmap of the water normals which is more realistic

#define SHADOW_FILTER // Enable soft shadow filtering, if enabled shadows will appear softer, this costs performance
#define SHD_COL

#define SSGI // Enables SSGI, currently experimental and may not be very optimized, may improve the ambience of dark areas despite the noisiness
#define SSGI_STEPS 16 // SSGI steps, more steps means more quality, and more quality means more performance [16 20 24 28 32]
#define SSR // Enables SSR, may not look good in certain areas
#define SSR_STEPS 24 // SSR steps, more steps means more quality, and more quality means more performance [16 20 24 28 32]

#define DEFAULT_MAT // Enable inbuilt default PBR materials(emissiveMap, speculars, subsurface scaterring etc.). Disable to use your PBR resource packs(Latest LabPBR ver. required)
#define NOISE_SPEED 0.1 // The speed in which the noise randomises each frame. Set it zero if you want the noise to be constant each frame [0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]
#define BUFFER_VIEW gcolor // Views buffers. colortex1 views normals(in 0-1 range), colortex2 views lightmap and subsurface scattering material, colortex3-4 are the rest of the materials, colortex5 for reflection buffer, colortex6 for exposure buffer and colortex7 remains unused will output a black screen. [gcolor colortex1 colortex2 colortex3 colortex4 colortex5 colortex6 colortex7]

#define VOL_LIGHT_BRIGHTNESS 0.5 // The brightness/amount of volumetric lighting, set it to zero to disable it [0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]

/*---------------------------------------------------------------------------------------------------------------------------*/

#define LIGHT_COL_DAY vec3(2.0, 1.9, 1.8)
#define LIGHT_COL_NIGHT vec3(0.125, 0.25, 0.5)
#define LIGHT_COL_DAWN_DUSK vec3(1.2, 0.9, 0.3)

#define SKY_COL_DAY vec3(0.6, 0.8, 1)
#define SKY_COL_NIGHT vec3(0.0125, 0.025, 0.1)
#define SKY_COL_DAWN_DUSK vec3(0.12, 0.06, 0.24)

#ifdef NETHER
    #define BLOCK_LIGHT_COL vec3(1, 0.9, 0.8) // Nether light color
#elif defined END
    #define BLOCK_LIGHT_COL vec3(1, 0.9, 0.8) // The End light color
#else
    #define BLOCK_LIGHT_COL vec3(1, 0.9, 0.8) // Overworld light color
#endif