#ifndef FORCE_DISABLE_WEATHER
    #if WORLD_ID == 0
        #ifndef THUNDER_STRENGTH_DECLARED
            #define THUNDER_STRENGTH_DECLARED
            uniform float thunderStrength;
        #endif
        #ifdef DYNAMIC_WEATHER
            #ifndef DYNAMIC_THUNDER_DECLARED
                #define DYNAMIC_THUNDER_DECLARED
                uniform float dynamicThunderStrength;
            #endif
        #endif
        #ifndef RAIN_STRENGTH_DECLARED
            #define RAIN_STRENGTH_DECLARED
            uniform float rainStrength;
        #endif
    #endif
#endif

// Wave animation movements for water with storm wind reaction and indoor occlusion
vec3 getWaterWave(in vec3 vertexEyePlayerPos, in vec2 vertexWorldPosXZ, in float id, in float outside, in float currTime){
    // Current affected water blocks
    if(CURRENT_SPEED > 0.0 && id >= 11100.0 && id <= 11199.0){
        // Wind exposure: indoor water (caves, houses, under roofs) has NO wind
        float windExposure = smoothstep(0.70, 0.98, outside);

        #if WORLD_ID == 0 && !defined FORCE_DISABLE_WEATHER
            #ifdef DYNAMIC_WEATHER
                float stormWind = dynamicThunderStrength;
            #else
                float stormWind = thunderStrength;
            #endif
            float totalStorm = clamp(stormWind * 1.35 + rainStrength * 0.40, 0.0, 1.8) * windExposure;
        #else
            const float totalStorm = 0.0;
        #endif

        // Calm baseline current swell
        float baseSwell = cos(-sumOf(vertexWorldPosXZ) * CURRENT_FREQUENCY + currTime * CURRENT_SPEED);

        if(totalStorm > 0.001){
            // Storm wind creates rolling oceanic swells and choppy cross-waves
            float stormSpeed = CURRENT_SPEED * (1.0 + totalStorm * 1.8);
            float swell1 = sin((vertexWorldPosXZ.x * 0.75 + vertexWorldPosXZ.y * 0.45) * CURRENT_FREQUENCY + currTime * stormSpeed);
            float swell2 = cos((vertexWorldPosXZ.x * 0.35 - vertexWorldPosXZ.y * 0.85) * (CURRENT_FREQUENCY * 1.4) + currTime * (stormSpeed * 1.35)) * 0.55;
            float stormChop = sin(sumOf(vertexWorldPosXZ) * (CURRENT_FREQUENCY * 2.5) - currTime * (stormSpeed * 2.2)) * 0.25;

            float combinedStormSwell = swell1 + swell2 + stormChop;
            float waveHeight = 0.05 + totalStorm * 0.16;

            vertexEyePlayerPos.y += mix(baseSwell * 0.05, combinedStormSwell * waveHeight, min(1.0, totalStorm * 1.2));
            // Horizontal wave drift along prevailing wind direction
            vertexEyePlayerPos.xz += vec2(0.85, 0.53) * (combinedStormSwell * (0.035 * totalStorm));
        } else {
            // Calm weather or indoor water (indoor water has gentler, peaceful current)
            float calmFactor = mix(0.5, 1.0, windExposure);
            vertexEyePlayerPos.y += baseSwell * (0.05 * calmFactor);
        }
    }

    return vertexEyePlayerPos;
}

// 4-argument overload defaulting outside to 1.0 for backwards compatibility
vec3 getWaterWave(in vec3 vertexEyePlayerPos, in vec2 vertexWorldPosXZ, in float id, in float currTime){
    return getWaterWave(vertexEyePlayerPos, vertexWorldPosXZ, id, 1.0, currTime);
}