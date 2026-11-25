// Light Color & Intensity (converted to linear space BEFORE blending, so day cycle transitions blend in linear space)
// All functions return LINEAR colors. The toLinear() calls on macro constants are folded at compile time.
vec3 worldLightConstant(){
    return toLinear(vec3(WORLD_LIGHT_CR, WORLD_LIGHT_CG, WORLD_LIGHT_CB) * (WORLD_LIGHT_CI / 255.0));
}

#if WORLD_DAYCYCLE == 1
    vec3 worldLightDay(){
        return toLinear(vec3(WORLD_LIGHT_DR, WORLD_LIGHT_DG, WORLD_LIGHT_DB) * (WORLD_LIGHT_DI / 255.0));
    }

    vec3 worldLightTwilight(){
        return toLinear(vec3(WORLD_LIGHT_TR, WORLD_LIGHT_TG, WORLD_LIGHT_TB) * (WORLD_LIGHT_TI / 255.0));
    }

    vec3 worldLightNight(){
        return toLinear(vec3(WORLD_LIGHT_NR, WORLD_LIGHT_NG, WORLD_LIGHT_NB) * (WORLD_LIGHT_NI / 255.0));
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