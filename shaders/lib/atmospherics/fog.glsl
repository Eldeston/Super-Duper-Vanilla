float atmoFog(float playerPosY, float worldPosY, float playerPosLength, float heightDensity, float fogDensity){
    float fogAmount = heightDensity * exp(-playerPosY * fogDensity) * (1.0 - exp(-playerPosLength * worldPosY * fogDensity)) / worldPosY;
    return min(fogAmount, 1.0);
}

float getBorderFogAmount(float eyePlayerPosLength){
    return squared(hermiteMix(max(far - 16.0, 0.0), far, eyePlayerPosLength));
}

vec3 getFog(vec3 eyePlayerPos, vec3 color, vec3 fogCol, float worldPosY){
    vec3 nEyePlayerPos = normalize(eyePlayerPos);
    float waterVoid = smootherstep(nEyePlayerPos.y + (eyeBrightFact - 0.6));

    float eyePlayerPosLength = length(eyePlayerPos);
    float rainMult = 1.0 + rainStrength;

    #ifdef NETHER
        float c = 0.12; float b = 0.08; float o = 0.4;
    #elif defined END
        float c = 0.08; float b = 0.05; float o = 0.5;
    #else
        float c = 0.08 * rainMult; float b = 0.07 * rainMult; float o = 0.6;
    #endif

    if(isEyeInWater >= 1){
        c = mix(c * 1.44, c, waterVoid); b = mix(b * 1.44, b, waterVoid);
    }

    // Mist fog
    float mistFog = atmoFog(eyePlayerPos.y, worldPosY, eyePlayerPosLength, c, b) * o;
    color = mix(color, fogCol, mistFog * MIST_GROUND_FOG_BRIGHTNESS);

    // Border fog
    float borderFogAmount = getBorderFogAmount(eyePlayerPosLength);
    color = color * (1.0 - borderFogAmount) + fogCol * borderFogAmount;

    // Blindness fog
    float blindNessFog = exp(-eyePlayerPosLength * blindness);
    return color * blindNessFog;
}