// Star Intensity (blended across dayCycle when day cycle is active)
float worldStarIntensity(){
    #if WORLD_DAYCYCLE == 1
        return lerp(
            float(WORLD_STAR_NI),
            float(WORLD_STAR_TI),
            float(WORLD_STAR_DI),
            dayCycle
        );
    #else
        return float(WORLD_STAR_NI);
    #endif
}