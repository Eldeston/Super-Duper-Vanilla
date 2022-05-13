uniform float blindness;
uniform float far;

float atmoFog(float nPlayerPosY, float worldPosY, float playerPosLength, float totalDensity, float verticalFogDensity){
    return min(1.0, (totalDensity / verticalFogDensity) * exp(-max(worldPosY, 0.0) * verticalFogDensity) * (1.0 - exp(-playerPosLength * nPlayerPosY * verticalFogDensity)) / nPlayerPosY);
}

vec3 getFogRender(vec3 eyePlayerPos, vec3 color, vec3 fogCol, float worldPosY, bool skyMask){
    // If sky return fogCol
    if(skyMask) return fogCol * exp(-far * blindness * 0.375);
    
    float eyePlayerPosLength = length(eyePlayerPos);

    float totalFogDensity = FOG_TOTAL_DENSITY * ((isEyeInWater + newRainStrength) * PI + 1.0);
    float fogMult = min(1.0, MIST_GROUND_FOG_BRIGHTNESS * (1.0 + isEyeInWater));

    // Mist fog
    float mistFog = atmoFog(eyePlayerPos.y / eyePlayerPosLength, worldPosY, eyePlayerPosLength, totalFogDensity, FOG_VERTICAL_DENSITY) * fogMult;
    color = (fogCol - color) * mistFog + color;

    // Border fog
    #ifdef BORDER_FOG
        // Complementary's border fog calculation, thanks Emin!
        float borderFog = exp(-0.1 * pow(eyePlayerPosLength / far * 1.5, 10.0));
        color = (color - fogCol) * borderFog + fogCol;
    #endif

    // Blindness fog
    return color * exp(-eyePlayerPosLength * blindness * 0.375);
}