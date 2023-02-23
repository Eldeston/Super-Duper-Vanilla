float atmoFog(in float nPlayerPosY, in float worldPosY, in float playerPosLength, in float totalDensity, in float verticalFogDensity){
    return min(1.0, (totalDensity / verticalFogDensity) * exp2(-max(worldPosY, 0.0) * verticalFogDensity) * (1.0 - exp2(-playerPosLength * nPlayerPosY * verticalFogDensity)) / nPlayerPosY);
}

vec3 getFogRender(in vec3 color, in vec3 fogCol, in float viewDist, in float nEyePlayerPosY, in float worldPosY){
    #ifdef FORCE_DISABLE_WEATHER
        float verticalFogDensity = isEyeInWater == 0 ? FOG_VERTICAL_DENSITY : FOG_VERTICAL_DENSITY * 0.2;
        float totalFogDensity = isEyeInWater == 0 ? FOG_TOTAL_DENSITY : FOG_TOTAL_DENSITY * TAU;
    #else
        float verticalFogDensity = isEyeInWater == 0 ? FOG_VERTICAL_DENSITY - FOG_VERTICAL_DENSITY * rainStrength * 0.8 : FOG_VERTICAL_DENSITY * 0.2;
        float totalFogDensity = isEyeInWater == 0 ? FOG_TOTAL_DENSITY * (rainStrength * eyeBrightFact * PI + 1.0) : FOG_TOTAL_DENSITY * TAU;
    #endif

    float fogMult = min(1.0, GROUND_FOG_STRENGTH + GROUND_FOG_STRENGTH * isEyeInWater);

    // Mist fog
    float mistFog = atmoFog(nEyePlayerPosY, worldPosY, viewDist, totalFogDensity, verticalFogDensity) * fogMult;
    color = (fogCol - color) * mistFog + color;

    // Border fog
    #ifdef BORDER_FOG
        // Modified Complementary border fog calculation, thanks Emin!
        color = (color - fogCol) * exp2(-exp2(viewDist / far * 21.0 - 18.0)) + fogCol;
    #endif

    // Blindness fog
    return color * exp2(-viewDist * max(blindness, darknessFactor * 0.125 + darknessLightFactor));
}