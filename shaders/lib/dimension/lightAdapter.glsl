// Light Color & Intensity (normalized [0..1] RGB scaled by intensity)
vec3 worldLightConstant(){
    return vec3(WORLD_LIGHT_CR, WORLD_LIGHT_CG, WORLD_LIGHT_CB) / 255.0 * float(WORLD_LIGHT_CI);
}

#if WORLD_DAYCYCLE == 1
    vec3 worldLightDay(){
        return vec3(WORLD_LIGHT_DR, WORLD_LIGHT_DG, WORLD_LIGHT_DB) / 255.0 * float(WORLD_LIGHT_DI);
    }

    vec3 worldLightTwilight(){
        return vec3(WORLD_LIGHT_TR, WORLD_LIGHT_TG, WORLD_LIGHT_TB) / 255.0 * float(WORLD_LIGHT_TI);
    }

    vec3 worldLightNight(){
        return vec3(WORLD_LIGHT_NR, WORLD_LIGHT_NG, WORLD_LIGHT_NB) / 255.0 * float(WORLD_LIGHT_NI);
    }

    vec3 worldSunLight(){
        return mix(worldLightTwilight(), worldLightDay(), twilightPhase);
    }
#endif

vec3 worldLightColor(){
    #if WORLD_DAYCYCLE == 1
        return dayCycle > 1.0 ? worldSunLight() : worldLightNight();
    #else
        return worldLightConstant();
    #endif
}