/* --Main world/dimension settings-- */

/* This file allows custom macro settings for multiple worlds/dimensions,
allowing more compatibility for future worlds/dimensions and modded worlds/dimensions */

// Initial dimension id
#define WORLD_ID -1

// Enable if your world uses lighting from the sun/moon
// #define WORLD_LIGHT
// Enable sun/moon in your world. 1 for the standard sun and moon. 2 for the black hole.
#define WORLD_SUN_MOON 0
// Sun/moon size
#define WORLD_SUN_MOON_SIZE 0.0
// Enable sky ground
// #define WORLD_SKY_GROUND
// If the world utilizes vanilla fog color
#define WORLD_VANILLA_FOG_COLOR

// Force disable any clouds
#define FORCE_DISABLE_CLOUDS
// Force disable weather
#define FORCE_DISABLE_WEATHER
// Force disable day cycle
#define FORCE_DISABLE_DAY_CYCLE

// Enable stars in your world
// #define WORLD_STARS 1.0
// Enable aether particles in your world
// #define WORLD_AETHER
// Use a sky light amount if your world has an undefined sky lighting environment like The End or the Nether
#define WORLD_CUSTOM_SKYLIGHT 1.00

// Enable if your world uses a specific world color that uses the vanilla fog color, overrides sky colors
#define WORLDn1_VANILLA_FOGCOLI 1.00 // Intensity value [0.00 0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00 1.05 1.10 1.15 1.20 1.25 1.30 1.35 1.40 1.45 1.50 1.55 1.60 1.65 1.70 1.75 1.80 1.85 1.90 1.95 2.00]

#define FOGn1_VERTICAL_DENSITY 0.010 // Vertical density falloff, larger means thinner fog at high altitudes, but thicker fog in low altitudes [0.005 0.010 0.015 0.020 0.025 0.030 0.035 0.040 0.045 0.050 0.055 0.060 0.065 0.070 0.075 0.080 0.085 0.090 0.095 0.100 0.105 0.110 0.115 0.120 0.125 0.130 0.135 0.140 0.145 0.150 0.155 0.160 0.165 0.170 0.175 0.180 0.185 0.190 0.195 0.200 0.205 0.210 0.215 0.220 0.225 0.230 0.235 0.240 0.245 0.250 0.255 0.260 0.265 0.270 0.275 0.280 0.285 0.290 0.295 0.300 0.305 0.310 0.315 0.320 0.325 0.330 0.335 0.340 0.345 0.350 0.355 0.360 0.365 0.370 0.375 0.380 0.385 0.390 0.395 0.40 0.405 0.410 0.415 0.420 0.425 0.430 0.435 0.440 0.445 0.450 0.455 0.460 0.465 0.470 0.475 0.480 0.485 0.490 0.495 0.500]

#define FOGn1_TOTAL_DENSITY 0.020 // Total density falloff, larger means thicker fog [0.005 0.010 0.015 0.020 0.025 0.030 0.035 0.040 0.045 0.050 0.055 0.060 0.065 0.070 0.075 0.080 0.085 0.090 0.095 0.100 0.105 0.110 0.115 0.120 0.125 0.130 0.135 0.140 0.145 0.150 0.155 0.160 0.165 0.170 0.175 0.180 0.185 0.190 0.195 0.200 0.205 0.210 0.215 0.220 0.225 0.230 0.235 0.240 0.245 0.250 0.255 0.260 0.265 0.270 0.275 0.280 0.285 0.290 0.295 0.300 0.305 0.310 0.315 0.320 0.325 0.330 0.335 0.340 0.345 0.350 0.355 0.360 0.365 0.370 0.375 0.380 0.385 0.390 0.395 0.40 0.405 0.410 0.415 0.420 0.425 0.430 0.435 0.440 0.445 0.450 0.455 0.460 0.465 0.470 0.475 0.480 0.485 0.490 0.495 0.500]

// For the shader to read
#define FOG_VERTICAL_DENSITY FOGn1_VERTICAL_DENSITY
#define FOG_TOTAL_DENSITY FOGn1_TOTAL_DENSITY

// Enable if your world uses a custom fog color with an input, overrides sky colors
#define SKYn1_CR 39 // Red value [3 6 9 12 15 18 21 24 27 30 33 36 39 42 45 48 51 54 57 60 63 66 69 72 75 78 81 84 87 90 93 96 99 102 105 108 111 114 117 120 123 126 129 132 135 138 141 144 147 150 153 156 159 162 165 168 171 174 177 180 183 186 189 192 195 198 201 204 207 210 213 216 219 222 225 228 231 234 237 240 243 246 249 252 255]
#define SKYn1_CG 3 // Green value [3 6 9 12 15 18 21 24 27 30 33 36 39 42 45 48 51 54 57 60 63 66 69 72 75 78 81 84 87 90 93 96 99 102 105 108 111 114 117 120 123 126 129 132 135 138 141 144 147 150 153 156 159 162 165 168 171 174 177 180 183 186 189 192 195 198 201 204 207 210 213 216 219 222 225 228 231 234 237 240 243 246 249 252 255]
#define SKYn1_CB 78 // Blue value [3 6 9 12 15 18 21 24 27 30 33 36 39 42 45 48 51 54 57 60 63 66 69 72 75 78 81 84 87 90 93 96 99 102 105 108 111 114 117 120 123 126 129 132 135 138 141 144 147 150 153 156 159 162 165 168 171 174 177 180 183 186 189 192 195 198 201 204 207 210 213 216 219 222 225 228 231 234 237 240 243 246 249 252 255]
#define SKYn1_CI 1.00 // Intensity value [0.00 0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00 1.05 1.10 1.15 1.20 1.25 1.30 1.35 1.40 1.45 1.50 1.55 1.60 1.65 1.70 1.75 1.80 1.85 1.90 1.95 2.00]
const vec3 skyNetherCol = vec3(SKYn1_CR, SKYn1_CG, SKYn1_CB) * SKYn1_CI;

// Holds the data on how the light will change according to multiple environmental factors
#define SKY_COL_DATA_BLOCK fastSqrt(fogColor) * WORLDn1_VANILLA_FOGCOLI