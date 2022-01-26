/* --Main world/dimension settings-- */

/* This file allows custom macro settings for multiple worlds/dimensions,
allowing more compatibility for future worlds/dimensions and modded worlds/dimensions */

#define END

// Enable if your world uses lighting from the sun/moon
#define ENABLE_LIGHT
// Enable if your world uses a light color with an input, overrides light colors
#define USE_CUSTOM_LIGHTCOL vec3(0.70, 0.60, 0.80)

// Enable sun/moon in your world. 1 for the standard sun and moon. 2 for the black hole.
#define USE_SUN_MOON 2
// Enable stars in your world
#define USE_STARS_COL vec3(2)
// Enable horizon in your world
#define USE_HORIZON_COL pow(vec3(0.50, 0.25, 0.75), vec3(GAMMA))
// Force disable any clouds
#define FORCE_DISABLE_CLOUDS

// Enable if your world uses a specific world color that uses the vanilla fog color, overrides sky colors
// #define USE_VANILLA_FOGCOL fogColor
// Enable if your world uses a custom fog color with an input, overrides sky colors
#define USE_CUSTOM_FOGCOL vec3(0.15, 0.00, 0.30)
// Enable sky ground with adjustable albedo color
#define SKY_GROUND_COL pow(vec3(0, 0.064, 0.256), vec3(GAMMA))

// Use a sky light amount if your world has an undefined sky lighting environment like The End or the Nether
#define USE_SKY_LIGHT_AMOUNT 1.00

// Vertical density falloff, larger means less thick fog at high altitudes, but thicker fog in lower altitudes
#define FOG_VERTICAL_DENSITY_FALLOFF 0.008
// Total density falloff, larger means thicker fog
#define FOG_TOTAL_DENSITY_FALLOFF 0.008
// Fog opacity
#define FOG_OPACITY 0.25