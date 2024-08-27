// Modified Complementary border fog calculation, thanks Emin!
float getBorderFog(in float playerPosLength){
    return exp2(-exp2(playerPosLength / borderFar * 21.0 - 18.0));
}

float getAtmosphericFog(in float nPlayerPosY, in float worldPosY, in float playerPosLength, in float totalDensity, in float verticalFogDensity){
    return (totalDensity / verticalFogDensity) * exp2(-worldPosY * verticalFogDensity) * (1.0 - exp2(-playerPosLength * nPlayerPosY * verticalFogDensity)) / nPlayerPosY;
}

float getFogFactor(in float viewDist, in float nEyePlayerPosY, in float worldPosY){
    #ifdef FORCE_DISABLE_WEATHER
        float verticalFogDensity = isEyeInWater == 0 ? FOG_VERTICAL_DENSITY : FOG_VERTICAL_DENSITY * 0.2;
        float totalFogDensity = isEyeInWater == 0 ? FOG_TOTAL_DENSITY : FOG_TOTAL_DENSITY * TAU;
    #else
        float verticalFogDensity = isEyeInWater == 0 ? FOG_VERTICAL_DENSITY - FOG_VERTICAL_DENSITY * rainStrength * 0.8 : FOG_VERTICAL_DENSITY * 0.2;
        float totalFogDensity = isEyeInWater == 0 ? FOG_TOTAL_DENSITY * (rainStrength * eyeBrightFact * PI + 1.0) : FOG_TOTAL_DENSITY * TAU;
    #endif

    // Return fog
    return min(1.0, getAtmosphericFog(nEyePlayerPosY, worldPosY, viewDist, totalFogDensity, verticalFogDensity)) * min(1.0, GROUND_FOG_STRENGTH + GROUND_FOG_STRENGTH * isEyeInWater);
}

float getFogDarknessFactor(in float viewDist){
    // Blindness fog
    return exp2(-viewDist * max(blindness, darknessFactor * 0.125 + darknessLightFactor));
}