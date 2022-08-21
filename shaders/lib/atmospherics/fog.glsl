float atmoFog(float nPlayerPosY, float worldPosY, float playerPosLength, float totalDensity, float verticalFogDensity){
    return min(1.0, (totalDensity / verticalFogDensity) * exp(-max(worldPosY, 0.0) * verticalFogDensity) * (1.0 - exp(-playerPosLength * nPlayerPosY * verticalFogDensity)) / nPlayerPosY);
}

vec3 getFogRender(vec3 color, vec3 fogCol, float viewDist, float nEyePlayerPosY, float worldPosY){
    float verticalFogDensity = isEyeInWater == 0 ? FOG_VERTICAL_DENSITY - FOG_VERTICAL_DENSITY * rainStrength * 0.8 : FOG_VERTICAL_DENSITY * 0.2;
    float totalFogDensity = FOG_TOTAL_DENSITY * (isEyeInWater == 0 ? rainStrength * eyeBrightFact * PI + 1.0 : PI + 1.0);
    float fogMult = min(1.0, GROUND_FOG_AMOUNT + GROUND_FOG_AMOUNT * isEyeInWater);

    // Mist fog
    float mistFog = atmoFog(nEyePlayerPosY, worldPosY, viewDist, totalFogDensity, verticalFogDensity) * fogMult;
    color = (fogCol - color) * mistFog + color;

    // Border fog
    #ifdef BORDER_FOG
        // Modified Complementary border fog calculation, thanks Emin!
        color = (color - fogCol) * exp(-exp2(viewDist / far * 16.0 - 14.0)) + fogCol;
    #endif

    // Blindness fog
    return color * exp(-viewDist * max(blindness, darknessFactor * 0.125 + darknessLightFactor));
}