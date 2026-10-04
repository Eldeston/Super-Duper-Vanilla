#ifndef RAINBOW_GLSL
#define RAINBOW_GLSL

/*
================================ /// Super Duper Vanilla /// ================================

    Procedural Natural Double Rainbow & Rainsquare System
    - Natural, desaturated spectral colors (warm vermilion, amber, soft sage green, cyan, cerulean, lavender)
    - Delicate optical transparency (soft atmospheric transmission rather than opaque paint)
    - Minimum distance necessary for rain to reflect light (30-50m threshold based on raindrop density)
    - Physical block occlusion: solid terrain closer than the minimum distance occludes the rainbow
    - Shadow occlusion: does not render in shadows (single-tap shadow mapping test on raindrops)
    - Primary rainbow: Natural, Red outside, Violet inside (40°-42°)
    - Secondary rainbow: Fainter, outside primary, inverted colors (50°-53°)
    - Alexander's dark band in between
    - Follows SUN_MOON_ROUNDNESS:
        * 0.00 = Perfect square ("rainsquare")
        * 0.50 = Rounded square
        * 1.00 = Circle
    - Appears when raining and not totally overcast, opposite sun (day) or moon (night)

================================ /// Super Duper Vanilla /// ================================
*/

#ifndef PI
    #define PI 3.14159265
#endif
#ifndef TAU
    #define TAU 6.28318531
#endif

#ifndef IS_COLD_BIOME_DECLARED
    #define IS_COLD_BIOME_DECLARED
    uniform float isColdBiome;
    uniform float smoothBiomeTemp;
#endif


#ifndef RAINBOW_BRIGHTNESS
    #define RAINBOW_BRIGHTNESS 1.00
#endif

// Physical distance thresholds for rainbow reflection:
// In meteorological optics, individual raindrops in natural rainfall are sparse (~100-1000/m³).
// A minimum column depth / distance of ~30-50 meters (32-48 blocks) is required for
// raindrops to scatter enough light to reach human eye perceptual contrast against the background.
// Solid terrain closer than this distance physically blocks/occludes the rain curtain.
#ifndef RAINBOW_MIN_DISTANCE
    #define RAINBOW_MIN_DISTANCE 32.0 // Minimum distance in blocks for rain to reflect visible light (30-50m threshold)
#endif
#ifndef RAINBOW_DISTANCE
    #define RAINBOW_DISTANCE 64.0 // Rain column depth in blocks (in front of distant terrain, below clouds)
#endif

// Physically natural, desaturated rainbow chromaticity (soft natural pigments)
// t in [0, 1]: 0.0 = Red, 0.16 = Orange, 0.32 = Yellow, 0.50 = Green, 0.68 = Cyan, 0.84 = Blue, 1.0 = Violet
vec3 getNaturalRainbowSpectrum(in float t){
    t = saturate(t);

    // Natural, non-neon spectral pigments (in sRGB perceptual space)
    const vec3 cRed     = vec3(0.88, 0.28, 0.20); // Warm vermilion / coral red
    const vec3 cOrange  = vec3(0.92, 0.50, 0.18); // Warm apricot / amber
    const vec3 cYellow  = vec3(0.88, 0.78, 0.28); // Soft golden sunlight
    const vec3 cGreen   = vec3(0.35, 0.72, 0.40); // Natural meadow / sage green (NOT radioactive lime!)
    const vec3 cCyan    = vec3(0.24, 0.65, 0.78); // Soft sky turquoise
    const vec3 cBlue    = vec3(0.28, 0.46, 0.82); // Atmospheric cerulean / cornflower
    const vec3 cViolet  = vec3(0.50, 0.35, 0.68); // Soft lavender / periwinkle

    vec3 col;
    if(t < 0.16){
        col = mix(cRed, cOrange, t * 6.25);
    } else if(t < 0.32){
        col = mix(cOrange, cYellow, (t - 0.16) * 6.25);
    } else if(t < 0.50){
        col = mix(cYellow, cGreen, (t - 0.32) * 5.5555556);
    } else if(t < 0.68){
        col = mix(cGreen, cCyan, (t - 0.50) * 5.5555556);
    } else if(t < 0.84){
        col = mix(cCyan, cBlue, (t - 0.68) * 6.25);
    } else {
        col = mix(cBlue, cViolet, (t - 0.84) * 6.25);
    }

    // Natural atmospheric desaturation (forward scattering from raindrops adds diffuse white light)
    float lum = dot(col, vec3(0.299, 0.587, 0.114));
    col = mix(col, vec3(lum), 0.22);

    // Convert from perceptual sRGB to linear color space
    return toLinear(col);
}

// Evaluates spectral color for primary bow, secondary bow, and Alexander's dark band
vec3 evaluateRainbowBows(in float dist){
    // Rainbow angular radii (in tangent space, from real optics):
    // Primary bow: 40° (violet, inner) to 42° (red, outer) -> tan(40°)=0.839, tan(42°)=0.900
    // Alexander's dark band: 42° to 50°
    // Secondary bow: 50° (red, inner) to 53° (violet, outer) -> tan(50°)=1.192, tan(53°)=1.327
    const float r1Min = 0.839;
    const float r1Max = 0.900;
    const float r2Min = 1.192;
    const float r2Max = 1.327;

    // Primary Rainbow (soft, natural, Red outside, Violet inside)
    if(dist >= r1Min && dist <= r1Max){
        float t1 = (dist - r1Min) * (1.0 / (r1Max - r1Min));
        float s1 = sin(t1 * PI);
        float env1 = s1 * (1.15 - 0.15 * s1);
        vec3 primarySpectral = getNaturalRainbowSpectrum(1.0 - t1);
        return primarySpectral * (env1 * 0.30);
    }
    // Secondary Rainbow (fainter, around/outside primary, reversed order: Red inside, Violet outside)
    if(dist >= r2Min && dist <= r2Max){
        float t2 = (dist - r2Min) * (1.0 / (r2Max - r2Min));
        float s2 = sin(t2 * PI);
        float env2 = s2 * (1.15 - 0.15 * s2);
        vec3 secondarySpectral = getNaturalRainbowSpectrum(t2);
        return secondarySpectral * (env2 * 0.08);
    }
    // Subtle zero-order diffuse brightening inside the primary bow
    if(dist < r1Min && dist > 0.60){
        float innerGlow = smoothstep(0.60, r1Min, dist) * 0.012;
        return vec3(1.0, 0.96, 0.90) * innerGlow;
    }
    return vec3(0.0);
}

#if defined SHADOW_MAPPING && defined SHD_MAPPING_GLSL
vec3 getRainbowShadowCoord(in vec3 feetPos, in float bias){
    vec3 shadowViewPos = mat3(shadowModelView) * feetPos + shadowModelView[3].xyz;
    vec3 shdPos = vec3(shadowProjection[0].x, shadowProjection[1].y, shadowProjection[2].z) * shadowViewPos;
    shdPos.z += shadowProjection[3].z;
    return vec3(shdPos.xy / (length(shdPos.xy) * 2.0 + 0.2), (shdPos.z - bias) * 0.1) + 0.5;
}

float getRainbowShadowVisibility(in vec3 nEyePlayerPos, in vec3 feetPlayerPos, in float viewDist, in bool isSky){
    float vis = 1.0;

    // 1. Solid terrain / obstacle shadow test:
    // If the background surface (mountain, hill, ground, building) is in shadow,
    // the rainbow disappears in that shadow.
    if(!isSky && viewDist < shadowDistance){
        vec3 shdPosTerrain = getRainbowShadowCoord(feetPlayerPos, 0.003);
        vec3 shdColTerrain = getShdCol(shdPosTerrain);
        float terrainVis = dot(shdColTerrain, vec3(0.333333));
        if(terrainVis <= 0.001) return 0.0;
        vis = min(vis, terrainVis);
    }

    // 2. Rain column shadow test:
    // Test if direct sunlight reaches the rain droplets reflecting light along the line of sight.
    float rainDist = isSky ? RAINBOW_MIN_DISTANCE : min(viewDist * 0.75, RAINBOW_MIN_DISTANCE);
    vec3 rainFeetPos = nEyePlayerPos * rainDist;
    vec3 shdPosRain = getRainbowShadowCoord(rainFeetPos, 0.0);
    vec3 shdColRain = getShdCol(shdPosRain);
    float rainVis = dot(shdColRain, vec3(0.333333));
    if(rainVis <= 0.001) return 0.0;
    vis = min(vis, rainVis);

    #ifndef FORCE_DISABLE_DAY_CYCLE
        vis *= shdFade;
    #endif
    return vis;
}
#elif !defined FORCE_DISABLE_WEATHER
float getRainbowShadowVisibility(in vec3 nEyePlayerPos, in vec3 feetPlayerPos, in float viewDist, in bool isSky){
    #ifndef WORLD_CUSTOM_SKYLIGHT
        return smoothstep(0.05, 0.40, eyeSkylight);
    #else
        return 1.0;
    #endif
}
#else
float getRainbowShadowVisibility(in vec3 nEyePlayerPos, in vec3 feetPlayerPos, in float viewDist, in bool isSky){
    return 1.0;
}
#endif

vec3 getRainbowRender(in vec3 nEyePlayerPos, in vec3 skyPos, in float viewDist, in bool isSky, in vec3 feetPlayerPos, in bool isWater){
    #ifdef FORCE_DISABLE_WEATHER
        return vec3(0.0);
    #else
        #if WORLD_ID == 0
            #ifndef THUNDER_STRENGTH_DECLARED
                #define THUNDER_STRENGTH_DECLARED
                uniform float thunderStrength;
            #endif
            float rainbowWeatherFade = clamp(max(weatherFade, thunderStrength), 0.0, 1.0);
        #else
            float rainbowWeatherFade = weatherFade;
        #endif
        // Only active when raining, not totally overcast, and not underwater / looking through water
        if(rainStrength <= 0.005 || rainbowWeatherFade >= 0.95 || isEyeInWater != 0 || isWater) return vec3(0.0);

        // Snow / cold biome check (snow does not form rainbows)
        float liquidRain = 1.0 - saturate(isColdBiome * 1.5);
        if(liquidRain <= 0.005) return vec3(0.0);

        // Physical block occlusion:
        // Raindrops closer than RAINBOW_MIN_DISTANCE (30-50m threshold) are too sparse to reflect
        // enough light to form a discernible bow. Any solid blocks closer than RAINBOW_MIN_DISTANCE
        // physically occlude the rain curtain and the rainbow.
        // Between RAINBOW_MIN_DISTANCE and RAINBOW_DISTANCE, the illuminated rain column depth
        // accumulates smoothly, allowing the rainbow to appear in front of distant terrain.
        float blockOcclusion = isSky ? 1.0 : smoothstep(RAINBOW_MIN_DISTANCE, RAINBOW_DISTANCE, viewDist);
        if(blockOcclusion <= 0.001) return vec3(0.0);

        // Fade out at cloud ceiling (~185..195) where rain ceases
        float cloudCeilFade = 1.0 - smoothstep(185.0, 195.0, cameraPosition.y);
        if(cloudCeilFade <= 0.001) return vec3(0.0);

        // Rainbow visibility: rain presence * not totally overcast * depth fade
        float rainFactor = smoothstep(0.01, 0.20, rainStrength);
        float notOvercastFactor = 1.0 - smoothstep(0.70, 0.95, rainbowWeatherFade);
        float rainbowStrength = rainFactor * notOvercastFactor * liquidRain * blockOcclusion * cloudCeilFade;
        if(rainbowStrength <= 0.001) return vec3(0.0);

        // Anti-celestial coordinates in the Sun's celestial frame:
        // skyPos = mat3(shadowModelView) * nEyePlayerPos, where skyPos.z points towards the sun,
        // and skyPos.xy are aligned with the sun's local rotation and orientation axes.
        // Towards our shadow (the antisolar point), zShadow = -skyPos.z > 0.
        float zShadow = -skyPos.z;
        if(zShadow <= 0.20) return vec3(0.0); // Outside shadow hemisphere

        // Projected tangent-space coordinates aligned with the Sun's rotation in the sky
        vec2 projCoord = skyPos.xy / zShadow;

        // Distance metric adhering to SUN_MOON_ROUNDNESS:
        // SUN_MOON_ROUNDNESS = 0.00 -> Perfect square ("rainsquare"), rotated at the exact angle of the sun
        // SUN_MOON_ROUNDNESS = 0.50 -> Rounded square
        // SUN_MOON_ROUNDNESS = 1.00 -> Perfect circle
        float dBox = max(abs(projCoord.x), abs(projCoord.y));
        float dCirc = length(projCoord);
        float dist = mix(dBox, dCirc, SUN_MOON_ROUNDNESS);

        // Evaluate spectral bows (primary, secondary, inner glow)
        vec3 bowCol = evaluateRainbowBows(dist);
        if(bowCol == vec3(0.0)) return vec3(0.0);

        // Shadow occlusion test: accurate shadow test on terrain & rain column
        float shadowVis = getRainbowShadowVisibility(nEyePlayerPos, feetPlayerPos, viewDist, isSky);
        if(shadowVis <= 0.001) return vec3(0.0);

        // Determine active celestial body: Sun during day, Moon at night
        #ifdef FORCE_DISABLE_DAY_CYCLE
            vec3 lightSourceCol = lightCol;
        #else
            vec3 lightSourceCol = mix(moonCol * 0.35, sunCol, dayCycleAdjust);
        #endif

        // Modulate with incoming celestial light, settings, and shadow visibility
        return bowCol * (lightSourceCol * (rainbowStrength * RAINBOW_BRIGHTNESS * shadowVis));
    #endif
}

// Overload when isWater is not explicitly passed
vec3 getRainbowRender(in vec3 nEyePlayerPos, in vec3 skyPos, in float viewDist, in bool isSky, in vec3 feetPlayerPos){
    return getRainbowRender(nEyePlayerPos, skyPos, viewDist, isSky, feetPlayerPos, false);
}

// Overload when feetPlayerPos and isWater are not explicitly passed
vec3 getRainbowRender(in vec3 nEyePlayerPos, in vec3 skyPos, in float viewDist, in bool isSky){
    return getRainbowRender(nEyePlayerPos, skyPos, viewDist, isSky, nEyePlayerPos * min(viewDist, RAINBOW_DISTANCE), false);
}

// Overload for reflections and sky passes without depth
vec3 getRainbowRender(in vec3 nEyePlayerPos, in vec3 skyPos){
    return getRainbowRender(nEyePlayerPos, skyPos, 1000.0, true, nEyePlayerPos * RAINBOW_DISTANCE, false);
}

#endif // RAINBOW_GLSL
