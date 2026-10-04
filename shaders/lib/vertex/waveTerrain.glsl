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

// Wave animation movements for wind with storm gust reaction and indoor exclusion
vec3 getWindWave(in vec3 vertexEyePlayerPos, in vec2 vertexWorldPosXZ, in float midBlockY, in float id, in float outside, in float currTime){
    // Wind exposure: indoor blocks (under a roof, inside houses, caves) have NO wind
    float windExposure = smoothstep(0.70, 0.98, outside);
    if(windExposure <= 0.001) return vertexEyePlayerPos;

    #if WORLD_ID == 0 && !defined FORCE_DISABLE_WEATHER
        #ifdef DYNAMIC_WEATHER
            float stormWind = dynamicThunderStrength;
        #else
            float stormWind = thunderStrength;
        #endif
        float totalStorm = clamp(stormWind * 1.35 + rainStrength * 0.40, 0.0, 1.8);
    #else
        const float totalStorm = 0.0;
    #endif

    float basePos = -sumOf(id == 10801 ? floor(vertexWorldPosXZ) : vertexWorldPosXZ);
    float baseWave = sin(basePos * WIND_FREQUENCY + currTime * WIND_SPEED);

    float windStrength;
    if(totalStorm > 0.001){
        // Storm wind speed acceleration
        float stormTime = currTime * (WIND_SPEED * (1.0 + totalStorm * 1.8));
        // High-frequency buffeting gusts
        float gusts = sin(basePos * (WIND_FREQUENCY * 2.2) + stormTime * 1.7) * 0.55;
        // Fast flutter on leaves and foliage tips
        float flutter = sin((vertexWorldPosXZ.x - vertexWorldPosXZ.y) * 4.2 + stormTime * 2.8) * 0.25;
        // Directional prevailing wind lean
        float windSway = sin(stormTime * 0.7 + vertexWorldPosXZ.x * 0.3) * 0.35 + 0.65;
        float stormLean = windSway * totalStorm;

        float windIntensity = (baseWave + (gusts + flutter) * totalStorm) * (1.0 + totalStorm * 1.5) + stormLean * 0.8;
        windStrength = windIntensity * windExposure;
    } else {
        windStrength = baseWave * windExposure;
    }

    // Simple blocks, horizontal movement (Leaves)
    if(id <= 10099){
        vertexEyePlayerPos.xz -= windStrength * 0.1;
        #if WORLD_ID == 0
            vertexEyePlayerPos.y -= abs(windStrength) * (0.02 * totalStorm);
        #endif
        return vertexEyePlayerPos;
    }

    // Single and double grounded cutouts (Bushes, grass, flowers)
    if(id >= 10600 && id <= 10799){
        float isUpper = midBlockY - (id >= 10700 ? 1.5 : 0.5);
        vertexEyePlayerPos.xz += isUpper * windStrength * 0.1;
        #if WORLD_ID == 0
            // Bushes and foliage bend downwards slightly under heavy storm wind pressure
            vertexEyePlayerPos.y -= max(0.0, isUpper) * abs(windStrength) * (0.05 * totalStorm);
        #endif
        return vertexEyePlayerPos;
    }

    // Single hanging cutouts
    if(id >= 10800 && id <= 10899){
        float isLower = midBlockY + 0.5;
        vertexEyePlayerPos.xz += isLower * windStrength * 0.05;
        return vertexEyePlayerPos;
    }

    // Multi wall cutouts
    if(id >= 10900){
        vertexEyePlayerPos.xz += windStrength * 0.05;
        return vertexEyePlayerPos;
    }

    return vertexEyePlayerPos;
}

// Wave animation movements for water current
vec3 getCurrentWave(in vec3 vertexEyePlayerPos, in vec2 vertexWorldPosXZ, in float midBlockY, in float id, in float currTime){
    // Calculate current strength
    float currentStrength = cos(-sumOf(vertexWorldPosXZ) * CURRENT_FREQUENCY + currTime * CURRENT_SPEED);

    // Simple blocks, vertical movement
    if(id <= 11199){
        vertexEyePlayerPos.y += currentStrength * 0.05;
        return vertexEyePlayerPos;
    }

    // Single and double grounded cutouts
    if(id >= 11600 && id <= 11799){
        float isUpper = midBlockY - (id >= 11700 ? 1.5 : 0.5);
        vertexEyePlayerPos.xz += isUpper * currentStrength * 0.1;
        return vertexEyePlayerPos;
    }

    return vertexEyePlayerPos;
}

// Wave animation movements for shadow and terrain
vec3 getTerrainWave(in vec3 vertexEyePlayerPos, in vec2 vertexWorldPosXZ, in float midBlockY, in float id, in float outside, in float currTime){
    // Early exit immediately for non-waving blocks (stone, dirt, ores, wood, etc.)
    if(id < 10000.0 || id > 11799.0) return vertexEyePlayerPos;

    // Wind affected blocks
    if(WIND_SPEED > 0.0 && id <= 10999.0){
        return getWindWave(vertexEyePlayerPos, vertexWorldPosXZ, midBlockY, id, outside, currTime);
    }

    // Current affected blocks
    if(CURRENT_SPEED > 0.0 && id >= 11100.0){
        return getCurrentWave(vertexEyePlayerPos, vertexWorldPosXZ, midBlockY, id, currTime);
    }

    return vertexEyePlayerPos;
}