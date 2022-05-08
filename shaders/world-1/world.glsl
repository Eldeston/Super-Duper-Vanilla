/* --Main world/dimension settings-- */

/* This file allows custom macro settings for multiple worlds/dimensions,
allowing more compatibility for future worlds/dimensions and modded worlds/dimensions */

// Initial dimension id
#define WORLD_ID -1

// Enable if your world uses lighting from the sun/moon
// #define WORLD_LIGHT
// Enable sun/moon in your world. 1 for the standard sun and moon. 2 for the black hole.
#define WORLD_SUN_MOON 0
// Enable sky ground
// #define WORLD_SKY_GROUND
// Enable water normals
// #define WORLD_WATERNORM
// Force disable any clouds
#define FORCE_DISABLE_CLOUDS
// Force disable weather
#define FORCE_DISABLE_WEATHER

// Enable stars in your world
// #define WORLD_STARS 1.0
// Enable horizon in your world
// #define WORLD_HORIZONCOL fogColor

// Enable if your world uses a custom fog color with an input, overrides sky colors
#define WORLDn1_CUSTOM_FOGCOLR 39 // Red value [3 6 9 12 15 18 21 24 27 30 33 36 39 42 45 48 51 54 57 60 63 66 69 72 75 78 81 84 87 90 93 96 99 102 105 108 111 114 117 120 123 126 129 132 135 138 141 144 147 150 153 156 159 162 165 168 171 174 177 180 183 186 189 192 195 198 201 204 207 210 213 216 219 222 225 228 231 234 237 240 243 246 249 252 255]
#define WORLDn1_CUSTOM_FOGCOLG 3 // Green value [3 6 9 12 15 18 21 24 27 30 33 36 39 42 45 48 51 54 57 60 63 66 69 72 75 78 81 84 87 90 93 96 99 102 105 108 111 114 117 120 123 126 129 132 135 138 141 144 147 150 153 156 159 162 165 168 171 174 177 180 183 186 189 192 195 198 201 204 207 210 213 216 219 222 225 228 231 234 237 240 243 246 249 252 255]
#define WORLDn1_CUSTOM_FOGCOLB 78 // Blue value [3 6 9 12 15 18 21 24 27 30 33 36 39 42 45 48 51 54 57 60 63 66 69 72 75 78 81 84 87 90 93 96 99 102 105 108 111 114 117 120 123 126 129 132 135 138 141 144 147 150 153 156 159 162 165 168 171 174 177 180 183 186 189 192 195 198 201 204 207 210 213 216 219 222 225 228 231 234 237 240 243 246 249 252 255]
#define WORLDn1_CUSTOM_FOGCOLI 1.00 // Intensity value [0.00 0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00 1.05 1.10 1.15 1.20 1.25 1.30 1.35 1.40 1.45 1.50 1.55 1.60 1.65 1.70 1.75 1.80 1.85 1.90 1.95 2.00]

// Enable if your world uses a specific world color that uses the vanilla fog color, overrides sky colors
#define WORLDn1_VANILLA_FOGCOLI 1.00 // Intensity value [0.00 0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00 1.05 1.10 1.15 1.20 1.25 1.30 1.35 1.40 1.45 1.50 1.55 1.60 1.65 1.70 1.75 1.80 1.85 1.90 1.95 2.00]

// Use a sky light amount if your world has an undefined sky lighting environment like The End or the Nether
#define WORLD_SKYLIGHT 1.00

// Vertical density falloff, larger means less thick fog at high altitudes, but thicker fog in lower altitudes
#define WORLD_FOG_VERTICAL_DENSITY 0.025
// Total density falloff, larger means thicker fog
#define WORLD_FOG_TOTAL_DENSITY 0.025

// Holds the data on how the light will change according to multiple environmental factors
#define SKY_COL_DATA_BLOCK fastSqrt(fogColor) * WORLDn1_VANILLA_FOGCOLI