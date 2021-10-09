float atmoFog(float playerPosLength, float fogDensity){
    return 1.0 - exp(-playerPosLength * fogDensity);
}

float atmoFog(float playerPosY, float worldPosY, float playerPosLength, float totalDensity, float verticalFogDensity){
    // Nan fix
    if(playerPosY == 0) playerPosY = 0.001;
    if(worldPosY == 0) worldPosY = 0.001;
    return min(1.0, (totalDensity / verticalFogDensity) * exp(-worldPosY * verticalFogDensity) * (1.0 - exp(-playerPosLength * playerPosY * verticalFogDensity)) / playerPosY);
}

float getBorderFogAmount(float eyePlayerPosLength, float edge){
    // Complementary's border fog calculation, thanks Emin!
    return 1.0 - exp(-0.1 * pow(eyePlayerPosLength / edge * 1.5, 10.0));
}

vec3 getFogRender(vec3 eyePlayerPos, vec3 color, vec3 fogCol, float worldPosY, bool cloudMask, bool skyMask){
    float eyePlayerPosLength = length(eyePlayerPos);

    // Border fog
    #ifdef BORDER_FOG
        float borderFog = getBorderFogAmount(eyePlayerPosLength, cloudMask ? far * 2.0 : far);
        color = color * (1.0 - borderFog) + fogCol * borderFog;
    #else
        color = skyMask ? fogCol : color;
    #endif

    float c = FOG_TOTAL_DENSITY_FALLOFF * (1.0 + isEyeInWater * 2.5 + rainStrength) * 1.28;
    float b = FOG_VERTICAL_DENSITY_FALLOFF * 1.28;
    float fogMult = min(1.0, FOG_OPACITY * MIST_GROUND_FOG_BRIGHTNESS * (1.0 + isEyeInWater * 0.32 + rainStrength) * 1.28);

    // Mist fog
    float mistFog = (isEyeInWater == 0 ? atmoFog(normalize(eyePlayerPos).y, worldPosY, eyePlayerPosLength, c, b) :
        atmoFog(eyePlayerPosLength, b)) * fogMult;
    color = color * (1.0 - mistFog) + fogCol * mistFog;

    // Blindness fog
    return color * exp(-eyePlayerPosLength * blindness * 0.375);
}