float atmoFog(float playerPosLength, float fogDensity){
    return 1.0 - exp(-playerPosLength * fogDensity);
}

float atmoFog(float playerPosY, float worldPosY, float playerPosLength, float totalDensity, float verticalFogDensity){
    return min(1.0, totalDensity * exp(-playerPosY * verticalFogDensity) * (1.0 - exp(-playerPosLength * worldPosY * verticalFogDensity)) / worldPosY);
}

float getBorderFogAmount(float eyePlayerPosLength, float edge){
    return smoothstep(max(edge - 64.0, 0.0), max(edge - 32.0, 16.0), eyePlayerPosLength);
}

vec3 getFogRender(vec3 eyePlayerPos, vec3 color, vec3 fogCol, float worldPosY, bool cloudMask, bool skyMask){
    vec3 nEyePlayerPos = normalize(eyePlayerPos);

    float eyePlayerPosLength = length(eyePlayerPos);

    float c = FOG_TOTAL_DENSITY_FALLOFF * rainMult * underWaterMult * 1.2;
    float b = FOG_VERTICAL_DENSITY_FALLOFF * rainMult * underWaterMult * 1.2;
    float o = min(1.0, FOG_OPACITY * underWaterMult * 1.2 + rainMult * underWaterMult * 0.16);

    // Border fog
    #ifdef BORDER_FOG
        float borderFog = getBorderFogAmount(eyePlayerPosLength, cloudMask ? min(far * 4.0, 256.0) : far);
        color = color * (1.0 - borderFog) + fogCol * borderFog;
    #else
        color = skyMask ? fogCol : color;
    #endif

    // Mist fog
    float mistFog = (isEyeInWater == 0 ? atmoFog(eyePlayerPos.y, worldPosY, eyePlayerPosLength, c, b) :
        atmoFog(eyePlayerPosLength, b)) * o * MIST_GROUND_FOG_BRIGHTNESS;
    
    if(!cloudMask) color = color * (1.0 - mistFog) + fogCol * mistFog;

    // Blindness fog
    float blindNessFog = exp(-eyePlayerPosLength * blindness * 0.32);
    return color * blindNessFog;
}