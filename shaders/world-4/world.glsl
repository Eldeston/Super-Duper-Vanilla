/* --Main world/dimension settings-- */
// Credits: Kawwabi

/* This file allows custom macro settings for multiple worlds/dimensions,
allowing more compatibility for future worlds/dimensions and modded worlds/dimensions */

// Initial dimension id
#define WORLD_ID -4

// Disable sun/moon lighting
// #define WORLD_LIGHT
// Disable sun/moon rendering. 1 for the standard sun and moon. 2 for the black hole.
#define WORLD_SUN_MOON 0
// Sun/moon size
#define WORLD_SUN_MOON_SIZE 0.0

// Force disable any clouds
#define FORCE_DISABLE_CLOUDS
// Force disable weather
#define FORCE_DISABLE_WEATHER
// Force disable day cycle
#define FORCE_DISABLE_DAY_CYCLE

// No sky ground
// #define WORLD_SKY_GROUND
// No aether particles
// #define WORLD_AETHER

// High skylight so the pure white sky is clearly visible and fabric blocks get consistent illumination
#define WORLD_CUSTOM_SKYLIGHT 1.0

// No stars
// #define WORLD_STARS

// Use vanilla fog color as the sky color (biome provides the background for dimensional doors' limbo)
#define WORLD_VANILLA_FOG_COLOR
#define WORLDn4_VANILLA_FOGCOLI 1.5 // Intensity value [0.00 0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00 1.05 1.10 1.15 1.20 1.25 1.30 1.35 1.40 1.45 1.50 1.55 1.60 1.65 1.70 1.75 1.80 1.85 1.90 1.95 2.00]
#define SKY_COLOR_DATA_BLOCK fogColor * WORLDn4_VANILLA_FOGCOLI

// Override block light color to use pure white instead of warm-tinted block light
#define WORLD_WHITE_LIGHTING

#define FOGn4_VERTICAL_DENSITY 0.000 // Vertical density falloff [0.005 0.010 0.015 0.020 0.025 0.030 0.035 0.040 0.045 0.050 0.055 0.060 0.065 0.070 0.075 0.080 0.085 0.090 0.095 0.100 0.105 0.110 0.115 0.120 0.125 0.130 0.135 0.140 0.145 0.150 0.155 0.160 0.165 0.170 0.175 0.180 0.185 0.190 0.195 0.200 0.205 0.210 0.215 0.220 0.225 0.230 0.235 0.240 0.245 0.250 0.255 0.260 0.265 0.270 0.275 0.280 0.285 0.290 0.295 0.300 0.305 0.310 0.315 0.320 0.325 0.330 0.335 0.340 0.345 0.350 0.355 0.360 0.365 0.370 0.375 0.380 0.385 0.390 0.395 0.40 0.405 0.410 0.415 0.420 0.425 0.430 0.435 0.440 0.445 0.450 0.455 0.460 0.465 0.470 0.475 0.480 0.485 0.490 0.495 0.500]

#define FOGn4_TOTAL_DENSITY 0.000 // Total density falloff [0.005 0.010 0.015 0.020 0.025 0.030 0.035 0.040 0.045 0.050 0.055 0.060 0.065 0.070 0.075 0.080 0.085 0.090 0.095 0.100 0.105 0.110 0.115 0.120 0.125 0.130 0.135 0.140 0.145 0.150 0.155 0.160 0.165 0.170 0.175 0.180 0.185 0.190 0.195 0.200 0.205 0.210 0.215 0.220 0.225 0.230 0.235 0.240 0.245 0.250 0.255 0.260 0.265 0.270 0.275 0.280 0.285 0.290 0.295 0.300 0.305 0.310 0.315 0.320 0.325 0.330 0.335 0.340 0.345 0.350 0.355 0.360 0.365 0.370 0.375 0.380 0.385 0.390 0.395 0.40 0.405 0.410 0.415 0.420 0.425 0.430 0.435 0.440 0.445 0.450 0.455 0.460 0.465 0.470 0.475 0.480 0.485 0.490 0.495 0.500]

// For the shader to read
#define FOG_VERTICAL_DENSITY FOGn4_VERTICAL_DENSITY
#define FOG_TOTAL_DENSITY FOGn4_TOTAL_DENSITY

// Make blocks glow at full brightness (like having night vision) in personal pockets
#define WORLD_BLOCK_GLOW

// Make entities glow as if under a 15-level light source inside dimdoors
// #define WORLD_ENTITY_GLOW
