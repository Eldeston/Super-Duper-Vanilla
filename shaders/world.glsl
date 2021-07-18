/* --Main world/dimension settings-- */

/* This file allows custom macro settings for multiple worlds/dimensions,
allowing more compatibility for future worlds/dimensions and modded worlds/dimensions */

#define OVERWORLD

// Enable if your world uses fixed light direction
// #define FIXED_LIGHTDIR
// Enable if your world uses lighting from the sun/moon
#define ENABLE_LIGHT
// Enable if your world uses a custom fog color with an input, overrides sky colors
// #define USE_CUSTOM_LIGHTCOL vec3(0)

// Enable if your world uses a specific world color that uses the vanilla fog color, overrides sky colors
// #define USE_VANILLA_FOGCOL
// Enable if your world uses a custom fog color with an input, overrides sky colors
// #define USE_CUSTOM_FOGCOL vec3(0)

// Enable if your world has a sky lightmap, or none
#define USE_SKY_LIGHTMAP
// Sky light amount
#define SKY_LIGHT_AMOUNT 1.00

// Vertical density falloff, larger means less thick fog at high altitudes, but thicker fog in lower altitudes
#define FOG_VERTICAL_DENSITY_FALLOFF 0.04
// Total density falloff, larger means thicker fog
#define FOG_TOTAL_DENSITY_FALLOFF 0.10
// Fog opacity
#define FOG_OPACITY 0.50