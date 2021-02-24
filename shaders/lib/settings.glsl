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

#define LIGHTMAP_NOISE // Enable noise on lightmaps

#define LIGHTMAP_NOISE_INTENSITY 0.05 // Lightmap noise intensity [0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0]

#define AUTO_EXPOSURE // Auto exposure, can be potentionally buggy in certain situations
#define SHADOW_EXPOSURE 1.2 // The amount of exposure in dark areas [0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0 1.05 1.1 1.15 1.2 1.25 1.3 1.35 1.4 1.45 1.5 1.55 1.6 1.65 1.7 1.75 1.8 1.85 1.9 1.95 2.0]
#define HIGHLIGHT_EXPOSURE 0.8 // The amount of exposure in lit areas [0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0 1.05 1.1 1.15 1.2 1.25 1.3 1.35 1.4 1.45 1.5 1.55 1.6 1.65 1.7 1.75 1.8 1.85 1.9 1.95 2.0]

#define UNDERWATER_DISTORTION // Distorts view when underwater
#define DISTORT_AMOUNT 0.004 // Distortion amount [0.0005 0.001 0.0015 0.002 0.0025 0.003 0.0035 0.004 0.0045 0.005 0.0055 0.006 0.0065 0.007 0.0075 0.008 0.0085 0.009 0.0095 0.01]
#define DISTORT_SPEED 2.0 // Distortion speed [1.0 2.0 3.0 4.0 5.0 6.0 7.0 8.0 9.0 10.0]
#define DISTORT_FREQUENCY 64.0 // Distortion frequency [1.0 2.0 4.0 8.0 16.0 32.0 64.0 128.0 256.0]

#define SATURATION 1.4 // Saturation [0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0 1.05 1.1 1.15 1.2 1.25 1.3 1.35 1.4 1.45 1.5 1.55 1.6 1.65 1.7 1.75 1.8 1.85 1.9 1.95 2.0]
#define EXPOSURE 1.0 // Exposure [0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0 1.05 1.1 1.15 1.2 1.25 1.3 1.35 1.4 1.45 1.5 1.55 1.6 1.65 1.7 1.75 1.8 1.85 1.9 1.95 2.0]
#define CONTRAST 1.1 // Contrast [0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0 1.05 1.1 1.15 1.2 1.25 1.3 1.35 1.4 1.45 1.5 1.55 1.6 1.65 1.7 1.75 1.8 1.85 1.9 1.95 2.0]
#define GAMMA 1.2 // Gamma [0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0 1.05 1.1 1.15 1.2 1.25 1.3 1.35 1.4 1.45 1.5 1.55 1.6 1.65 1.7 1.75 1.8 1.85 1.9 1.95 2.0]

#define WATER_BLUR_SIZE 8.0 // Water blur size, the smaller the sharper the waves look, the larger the smoother the waves look [1.0 2.0 4.0 8.0 12.0 16.0 32.0]
#define WATER_DEPTH_SIZE 6 // The depth amount of the water, the smaller the more deeper it looks [1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16]
#define WATER_TILE_SIZE 24 // Tile size of the water [8 16 24 32 40 48 56 64 72 80]
#define INVERSE // Inverses the heightmap of the water normals which is more realistic

#define SHADOW_FILTER // Enable soft shadow filtering, if enabled shadows will appear softer, this costs performance
#define SHD_COL 

#define DEFAULT_MAT // Enable inbuilt default PBR materials (emissiveMap, speculars, subsurface scaterring etc.)

/*---------------------------------------------------------------------------------------------------------------------------*/

#define LIGHT_COL_DAY vec3(210.0/255.0, 180.0/255.0, 150.0/255.0)
#define LIGHT_COL_NIGHT vec3(30.0/255.0, 60.0/255.0, 120.0/255.0)
#define LIGHT_COL_DAWN_DUSK vec3(1.0, 210.0/255.0, 90.0/255.0)

#define SKY_COL_DAY vec3(112.0/255.0, 180.0/255.0, 1.0)
#define SKY_COL_NIGHT vec3(0.0, 12.0/255.0, 36.0/255.0)
#define SKY_COL_DAWN_DUSK vec3(50.0/255.0, 25.0/255.0, 62.5/255.0)

#define FOG_COL_DAY vec3(0.9)
#define FOG_COL_NIGHT vec3(0.05, 0.1, 0.2)
#define FOG_COL_DAWN_DUSK vec3(0.05, 0.1, 0.2)

#ifdef NETHER
    #define BLOCK_LIGHT_COL vec3(1.0, 0.8, 0.6) // Nether light color
    #define BLOCK_AMBIENT vec3(0.375, 0.375, 0.25) // Nether ambient
#elif defined END
    #define BLOCK_LIGHT_COL vec3(1.0, 0.9, 0.8) // The End light color
    #define BLOCK_AMBIENT vec3(0.28, 0.28, 0.35) // The End ambient
#else
    #define BLOCK_LIGHT_COL vec3(0.99, 0.91, 0.84) // Overworld light color
    #define BLOCK_AMBIENT vec3(0.3, 0.3, 0.4) // Overworld ambient
#endif