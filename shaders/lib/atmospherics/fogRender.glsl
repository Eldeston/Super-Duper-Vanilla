// Modified Complementary border fog calculation, thanks Emin!
float getBorderFog(in float playerPosLength){
    return exp2(-exp2(playerPosLength / borderFar * 21.0 - 18.0));
}
// Ground fog calculation: stable optical depth integration through exponential atmosphere
// Prevents numerical explosion when looking downwards or at high altitudes
float getAtmosphericFog(in float nPlayerPosY, in float worldPosY, in float playerPosLength, in float totalDensity, in float verticalFogDensity){
    float camY = max(0.0, cameraPosition.y);
    float tgtY = max(0.0, worldPosY);
    float minY = min(camY, tgtY);
    float dy = abs(tgtY - camY);
    float k = max(0.0001, verticalFogDensity);
    float kDy = max(dy * k, 0.0001);
    float heightIntegral = (1.0 - exp2(-kDy)) / kDy;
    float opticalDepth = totalDensity * playerPosLength * exp2(-minY * k) * heightIntegral;
    return 1.0 - exp2(-opticalDepth);
}

float getFogFactor(in float viewDist, in float nEyePlayerPosY, in float worldPosY){
    #ifdef FORCE_DISABLE_WEATHER
        float verticalFogDensity = isEyeInWater == 0 ? FOG_VERTICAL_DENSITY : FOG_VERTICAL_DENSITY * 0.2;
        float totalFogDensity = isEyeInWater == 0 ? FOG_TOTAL_DENSITY : FOG_TOTAL_DENSITY * TAU;
    #else
        // Gentle atmospheric rain haze instead of blinding opaque fog wall
        float verticalFogDensity = isEyeInWater == 0 ? FOG_VERTICAL_DENSITY * (1.0 - weatherFade * 0.20) : FOG_VERTICAL_DENSITY * 0.2;
        float totalFogDensity = isEyeInWater == 0 ? FOG_TOTAL_DENSITY * (1.0 + weatherFade * 0.45) : FOG_TOTAL_DENSITY * TAU;
    #endif

    // Return fog, capped with ground fog strength
    return min(1.0, getAtmosphericFog(nEyePlayerPosY, max(0.0, worldPosY), viewDist, totalFogDensity, verticalFogDensity) * min(1.0, GROUND_FOG_STRENGTH + GROUND_FOG_STRENGTH * isEyeInWater));
}

float getFogEffectFactor(in float viewDist){
    // Blindness fog
    return exp2(-viewDist * effectFactor);
}