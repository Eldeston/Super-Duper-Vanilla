/* --Main world/dimension settings-- */

/* This file allows custom macro settings for multiple worlds/dimensions,
allowing more compatibility for future worlds/dimensions and modded worlds/dimensions */

#define END

// Enable if your world uses fixed light direction
#define FIXED_LIGHTDIR
// Enable if your world uses lighting from the sun/moon
#define ENABLE_LIGHT
// Enable if your world uses a light color with an input, overrides light colors
#define USE_CUSTOM_LIGHTCOL vec3(0.45, 0.4, 0.8)

// Enable if your world uses a specific world color that uses the vanilla fog color, overrides sky colors
// #define USE_VANILLA_FOGCOL fogColor
// Enable if your world uses a custom fog color with an input, overrides sky colors
#define USE_CUSTOM_FOGCOL vec3(0.1125, 0.1, 0.2)

// Enable if your world has a sky lightmap
// #define USE_SKY_LIGHTMAP
// Sky light amount
#define SKY_LIGHT_AMOUNT 1.00

// Fog height density
#define HEIGHT_FOG_DENSITY 0.08
// Fog density
#define FOG_DENSITY 0.05
// Fog opacity
#define FOG_OPACITY 0.50