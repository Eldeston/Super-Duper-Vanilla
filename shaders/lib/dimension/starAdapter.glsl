// Star Intensity (blended across dayCycle when day cycle is active)
float worldStarIntensity(){
    #if WORLD_DAYCYCLE == 1
        return lerp(
            WORLD_STAR_NI,
            WORLD_STAR_TI,
            WORLD_STAR_DI,
            dayCycle
        );
    #else
        return WORLD_STAR_CI;
    #endif
}