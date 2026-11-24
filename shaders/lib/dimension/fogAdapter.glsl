// Fog Densities (blended across dayCycle when day cycle is active)
float worldFogTotalDensity(){
    #if WORLD_DAYCYCLE == 1
        return lerp(
            WORLD_FOG_TOTAL_NI,
            WORLD_FOG_TOTAL_TI,
            WORLD_FOG_TOTAL_DI,
            dayCycle
        );
    #else
        return WORLD_FOG_TOTAL_CI;
    #endif
}

float worldFogVerticalDensity(){
    #if WORLD_DAYCYCLE == 1
        return lerp(
            WORLD_FOG_VERTICAL_NI,
            WORLD_FOG_VERTICAL_TI,
            WORLD_FOG_VERTICAL_DI,
            dayCycle
        );
    #else
        return WORLD_FOG_VERTICAL_CI;
    #endif
}