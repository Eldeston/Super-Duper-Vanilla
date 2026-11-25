// Sky Color & Intensity (normalized [0..1] RGB scaled by intensity)
vec3 worldSkyConstant(){
    return vec3(WORLD_SKY_CR, WORLD_SKY_CG, WORLD_SKY_CB) * (WORLD_SKY_CI / 255.0);
}

#if WORLD_DAYCYCLE == 1
    vec3 worldSkyDay(){
        return vec3(WORLD_SKY_DR, WORLD_SKY_DG, WORLD_SKY_DB) * (WORLD_SKY_DI / 255.0);
    }

    vec3 worldSkyTwilight(){
        return vec3(WORLD_SKY_TR, WORLD_SKY_TG, WORLD_SKY_TB) * (WORLD_SKY_TI / 255.0);
    }

    vec3 worldSkyNight(){
        return vec3(WORLD_SKY_NR, WORLD_SKY_NG, WORLD_SKY_NB) * (WORLD_SKY_NI / 255.0);
    }
#endif

#if WORLD_VANILLAFOG == 1
    vec3 worldVanillaFogSky(){
        return fastSqrt(fogColor);
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
            return mix(baseSky, worldVanillaFogSky(), 0.5);
        #elif WORLD_VANILLAFOG_MODE == 2
            return baseSky * worldVanillaFogSky();
        #else
            return worldVanillaFogSky();
        #endif
    #else
        return baseSky;
    #endif
}