#ifndef RAINBOW_GLSL
#define RAINBOW_GLSL

/*
================================ /// Super Duper Vanilla /// ================================

    Procedural Natural Double Rainbow & Rainsquare System
    - Natural, desaturated spectral colors (warm vermilion, amber, soft sage green, cyan, cerulean, lavender)
    - Delicate optical transparency (soft atmospheric transmission rather than opaque paint)
    - Rendered closer to the player at a fixed distance (lower/closer than clouds, in front of distant terrain)
    - Primary rainbow: Natural, Red outside, Violet inside
    - Secondary rainbow: Fainter, outside primary, inverted colors (Violet outside, Red inside)
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

#ifndef RAINBOW_DISTANCE
    #define RAINBOW_DISTANCE 64.0 // Fixed distance in blocks (closer to player, lower than the clouds)
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

vec3 getRainbowRender(in vec3 nEyePlayerPos, in vec3 skyPos, in float viewDist, in bool isSky){
    #ifdef FORCE_DISABLE_WEATHER
        return vec3(0.0);
    #else
        // Only active when raining, not totally overcast, and not underwater/in lava
        if(rainStrength <= 0.005 || weatherFade >= 0.95 || isEyeInWater != 0) return vec3(0.0);

        // Snow / cold biome check (snow does not form rainbows)
        float liquidRain = 1.0 - saturate(isColdBiome * 1.5);
        if(liquidRain <= 0.005) return vec3(0.0);

        // Render in front of the world, only fading out within arm's reach (< 1.5 blocks)
        // to prevent painting over held hands / tools
        float depthFade = isSky ? 1.0 : smoothstep(1.0, 2.5, viewDist);
        if(depthFade <= 0.001) return vec3(0.0);

        // Fade out at cloud ceiling (~185..195) where rain ceases
        float cloudCeilFade = 1.0 - smoothstep(185.0, 195.0, cameraPosition.y);
        if(cloudCeilFade <= 0.001) return vec3(0.0);

        // Rainbow visibility: rain presence * not totally overcast * depth fade
        float rainFactor = smoothstep(0.01, 0.20, rainStrength);
        float notOvercastFactor = 1.0 - smoothstep(0.70, 0.95, weatherFade);
        float rainbowStrength = rainFactor * notOvercastFactor * liquidRain * depthFade * cloudCeilFade;
        if(rainbowStrength <= 0.001) return vec3(0.0);

        // Determine active celestial body: Sun during day, Moon at night
        #ifdef FORCE_DISABLE_DAY_CYCLE
            vec3 lightSourceCol = lightCol;
        #else
            vec3 lightSourceCol = mix(moonCol * 0.35, sunCol, dayCycleAdjust);
        #endif

        // Exact anti-celestial vector (direction towards our shadow):
        // shadowModelView[0..2].z is the light vector in world space, so -lightDir points directly at our shadow
        vec3 lightDir = vec3(shadowModelView[0].z, shadowModelView[1].z, shadowModelView[2].z);
        vec3 shadowDir = -lightDir;

        // Orthonormal tangent basis centered on the shadow vector
        vec3 rightVec;
        if(abs(shadowDir.y) < 0.999){
            rightVec = normalize(cross(shadowDir, vec3(0.0, 1.0, 0.0)));
        } else {
            rightVec = vec3(1.0, 0.0, 0.0);
        }
        vec3 upVec = cross(rightVec, shadowDir);

        // View direction coordinates in the shadow-centered basis
        float zShadow = dot(nEyePlayerPos, shadowDir);
        if(zShadow <= 0.20) return vec3(0.0); // Outside shadow hemisphere

        float xShadow = dot(nEyePlayerPos, rightVec);
        float yShadow = dot(nEyePlayerPos, upVec);

        // Projected tangent-space coordinates centered exactly on our shadow
        vec2 projCoord = vec2(xShadow, yShadow) / zShadow;

        // Distance metric adhering to SUN_MOON_ROUNDNESS
        // SUN_MOON_ROUNDNESS = 0.00 -> Perfect square ("rainsquare")
        // SUN_MOON_ROUNDNESS = 0.50 -> Rounded square
        // SUN_MOON_ROUNDNESS = 1.00 -> Perfect circle
        float dBox = max(abs(projCoord.x), abs(projCoord.y));
        float dCirc = length(projCoord);
        float dist = mix(dBox, dCirc, SUN_MOON_ROUNDNESS);

        // Rainbow angular radii (in tangent space, from real optics):
        // Primary bow: 40° (violet, inner) to 42° (red, outer) -> tan(40°)=0.839, tan(42°)=0.900
        // Alexander's dark band: 42° to 50°
        // Secondary bow: 50° (red, inner) to 53° (violet, outer) -> tan(50°)=1.192, tan(53°)=1.327
        const float r1Min = 0.839;
        const float r1Max = 0.900;
        const float r2Min = 1.192;
        const float r2Max = 1.327;

        vec3 bowCol = vec3(0.0);

        // Primary Rainbow (soft, natural, Red outside, Violet inside)
        if(dist >= r1Min && dist <= r1Max){
            float t1 = (dist - r1Min) / (r1Max - r1Min); // 0 = inner (Violet), 1 = outer (Red)
            float env1 = pow(sin(t1 * PI), 0.85);
            vec3 primarySpectral = getNaturalRainbowSpectrum(1.0 - t1); // Red at outer, Violet at inner
            bowCol += primarySpectral * (env1 * 0.30); // Natural, delicate, translucent intensity
        }
        // Secondary Rainbow (fainter, around/outside primary, reversed order: Red inside, Violet outside)
        else if(dist >= r2Min && dist <= r2Max){
            float t2 = (dist - r2Min) / (r2Max - r2Min); // 0 = inner (Red), 1 = outer (Violet)
            float env2 = pow(sin(t2 * PI), 0.85);
            vec3 secondarySpectral = getNaturalRainbowSpectrum(t2); // Red at inner, Violet at outer
            bowCol += secondarySpectral * (env2 * 0.08); // Fainter secondary rainbow (~27% of primary)
        }
        // Subtle zero-order diffuse brightening inside the primary bow
        else if(dist < r1Min && dist > 0.60){
            float innerGlow = smoothstep(0.60, r1Min, dist) * 0.012;
            bowCol += vec3(1.0, 0.96, 0.90) * innerGlow;
        }

        if(bowCol == vec3(0.0)) return vec3(0.0);

        // Modulate with incoming celestial light and settings
        return bowCol * (lightSourceCol * (rainbowStrength * RAINBOW_BRIGHTNESS));
    #endif
}

// Overload for reflections and sky passes without depth
vec3 getRainbowRender(in vec3 nEyePlayerPos, in vec3 skyPos){
    return getRainbowRender(nEyePlayerPos, skyPos, 1000.0, true);
}

#endif // RAINBOW_GLSL
