// Sky Color & Intensity (converted to linear space BEFORE blending, so day cycle transitions blend in linear space)
// All functions return LINEAR colors. The toLinear() calls on macro constants are folded at compile time.
vec3 worldSkyConstant(){
    return toLinear(vec3(WORLD_SKY_CR, WORLD_SKY_CG, WORLD_SKY_CB) * (WORLD_SKY_CI / 255.0));
}

#if WORLD_DAYCYCLE == 1
    vec3 worldSkyDay(){
        return toLinear(vec3(WORLD_SKY_DR, WORLD_SKY_DG, WORLD_SKY_DB) * (WORLD_SKY_DI / 255.0));
    }

    vec3 worldSkyTwilight(){
        return toLinear(vec3(WORLD_SKY_TR, WORLD_SKY_TG, WORLD_SKY_TB) * (WORLD_SKY_TI / 255.0));
    }

    vec3 worldSkyNight(){
        return toLinear(vec3(WORLD_SKY_NR, WORLD_SKY_NG, WORLD_SKY_NB) * (WORLD_SKY_NI / 255.0));
    }
#endif

#if WORLD_VANILLAFOG == 1
    vec3 worldVanillaFogSky(){
        // Same value as before the linear conversion: toLinear(fastSqrt(fogColor))
        return toLinear(fastSqrt(fogColor));
    }
#endif

vec3 worldSkyColor(){
    #if WORLD_DAYCYCLE == 1
        vec3 baseSky = lerp(
            worldSkyNight(),
            worldSkyTwilight(),
            worldSkyDay(),
            dayCycle
        );
    #else
        vec3 baseSky = worldSkyConstant();
    #endif

    #if WORLD_VANILLAFOG == 1
        #if WORLD_VANILLAFOG_MODE == 1
            return mix(baseSky, worldVanillaFogSky(), WORLD_VANILLAFOG_STRENGTH);
        #elif WORLD_VANILLAFOG_MODE == 2
            return baseSky * mix(vec3(1.0), worldVanillaFogSky(), WORLD_VANILLAFOG_STRENGTH);
        #else
            return worldVanillaFogSky();
        #endif
    #else
        return baseSky;
    #endif
}