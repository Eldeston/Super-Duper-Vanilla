/* --Main world/dimension settings-- */

/* This file allows custom macro settings for multiple worlds/dimensions,
allowing more compatibility for future worlds/dimensions and modded worlds/dimensions */

#define NETHER

// Enable if your world uses fixed light direction
#define FIXED_LIGHTDIR
// Enable if your world uses lighting from the sun/moon
// #define ENABLE_LIGHT
// Enable if your world uses a custom fog color with an input, overrides sky colors
// #define USE_CUSTOM_LIGHTCOL vec3(0)

// Enable if your world uses a specific world color that uses the vanilla fog color, overrides sky colors
#define USE_VANILLA_FOGCOL sqrt(fogColor) * 0.75
// Enable if your world uses a custom fog color with an input, overrides sky colors
// #define USE_CUSTOM_FOGCOL vec3(0)

// Enable if your world has a sky lightmap
// #define USE_SKY_LIGHTMAP
// Sky light amount
#define SKY_LIGHT_AMOUNT 0.25

// Fog height density
#define HEIGHT_FOG_DENSITY 0.12
// Fog density
#define FOG_DENSITY 0.08
// Fog opacity
#define FOG_OPACITY 0.60