/* --Main world/dimension settings-- */

/* This file allows custom macro settings for multiple worlds/dimensions,
allowing more compatibility for future worlds/dimensions and modded worlds/dimensions */

#define OVERWORLD

// Enable if your world uses default shader lighting from the sun/moon
#define ENABLE_LIGHT
// Enable if your world uses a custom fog color with an input, overrides sky colors
// #define USE_CUSTOM_LIGHTCOL vec3(0)

// Enable sun/moon in your world
#define USE_SUN_MOON
// Enable stars in your world
#define USE_STARS_COL vec3(1)
// Enable horizon in your world
// #define USE_HORIZON_COL vec3(1)

// Enable if your world uses a specific world color that uses the vanilla fog color, overrides sky colors
// #define USE_VANILLA_FOGCOL
// Enable if your world uses a custom fog color with an input, overrides sky colors
// #define USE_CUSTOM_FOGCOL vec3(0)
// Enable sky ground with adjustable color
#define SKY_GROUND_COL vec3(0.128)

// Disable if your world has an undefined lighting environment like The End or the Nether
#define USE_SKY_LIGHTMAP
// Sky light amount
#define SKY_LIGHT_AMOUNT 1.00

// Vertical density falloff, larger means less thick fog at high altitudes, but thicker fog in lower altitudes
#define FOG_VERTICAL_DENSITY_FALLOFF 0.008
// Total density falloff, larger means thicker fog
#define FOG_TOTAL_DENSITY_FALLOFF 0.008
// Fog opacity
#define FOG_OPACITY 0.50