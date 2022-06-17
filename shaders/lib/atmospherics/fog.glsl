uniform float blindness;
uniform float far;

float atmoFog(float nPlayerPosY, float worldPosY, float playerPosLength, float totalDensity, float verticalFogDensity){
    return min(1.0, (totalDensity / verticalFogDensity) * exp(-max(worldPosY, 0.0) * verticalFogDensity) * (1.0 - exp(-playerPosLength * nPlayerPosY * verticalFogDensity)) / nPlayerPosY);
}

vec3 getFogRender(vec3 color, vec3 fogCol, float viewDist, float nEyePlayerPosY, float worldPosY){
    float totalFogDensity = FOG_TOTAL_DENSITY * ((isEyeInWater == 0 ? rainStrength * eyeBrightFact * PI : PI) + 1.0);
    float fogMult = min(1.0, MIST_GROUND_FOG_BRIGHTNESS * (1.0 + isEyeInWater));

    // Mist fog
    float mistFog = atmoFog(nEyePlayerPosY, worldPosY, viewDist, totalFogDensity, FOG_VERTICAL_DENSITY) * fogMult;
    color = (fogCol - color) * mistFog + color;

    // Border fog
    #ifdef BORDER_FOG
        // Complementary's border fog calculation, thanks Emin!
        color = (color - fogCol) * exp(-0.1 * pow(viewDist / far * 1.5, 10.0)) + fogCol;
    #endif

    // Blindness fog
    return color * exp(-viewDist * blindness * 0.375);
}