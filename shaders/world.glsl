/* --Main world/dimension settings-- */

/* This file allows custom macro settings for multiple worlds/dimensions,
allowing more compatibility for future worlds/dimensions and modded worlds/dimensions */

#define OVERWORLD

// Enable if your world uses default shader lighting from the sun/moon
#define ENABLE_LIGHT
// Enable if your world uses a custom fog color with an input, overrides sky colors
// #define USE_CUSTOM_LIGHTCOL vec3(0)

// Enable sun/moon in your world
#define USE_SUN_MOON 1
// Enable stars in your world
#define USE_STARS_COL vec3(pow((1.0 - day) * 2.0, GAMMA))
// Enable horizon in your world
// #define USE_HORIZON_COL vec3(1)
// Force disable any clouds
// #define FORCE_DISABLE_CLOUDS

// Enable if your world uses a specific world color that uses the vanilla fog color, overrides sky colors
// #define USE_VANILLA_FOGCOL fogColor
// Enable if your world uses a custom fog color with an input, overrides sky colors
// #define USE_CUSTOM_FOGCOL vec3(0)
// Enable sky ground with adjustable albedo color
#define SKY_GROUND_COL pow(vec3(0, 0.064, 0.256), vec3(GAMMA))

// Use a sky light amount if your world has an undefined sky lighting environment like The End or the Nether
// #define USE_SKY_LIGHT_AMOUNT 1.00

// Vertical density falloff, larger means less thick fog at high altitudes, but thicker fog in lower altitudes
#define FOG_VERTICAL_DENSITY_FALLOFF 0.005
// Total density falloff, larger means thicker fog
#define FOG_TOTAL_DENSITY_FALLOFF 0.0025
// Fog opacity
#define FOG_OPACITY 1.0