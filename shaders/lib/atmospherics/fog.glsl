float atmoFog(float playerPosY, float worldPosY, float playerPosLength, float heightDensity, float fogDensity){
    float fogAmount = heightDensity * exp(-playerPosY * fogDensity) * (1.0 - exp(-playerPosLength * worldPosY * fogDensity)) / worldPosY;
    return min(fogAmount, 1.0);
}

float getBorderFogAmount(float eyePlayerPosLength){
    return squared(hermiteMix(max(far - 32.0, 16.0), far, eyePlayerPosLength));
}

vec3 getFog(vec3 eyePlayerPos, vec3 color, vec3 fogCol, float worldPosY, float skyMask, float cloudMask){
    vec3 nEyePlayerPos = normalize(eyePlayerPos);
    float waterVoid = smootherstep(nEyePlayerPos.y + (eyeBrightFact - 0.6));

    float eyePlayerPosLength = length(eyePlayerPos);
    float rainMult = 1.0 + rainStrength * eyeBrightFact;

    #ifdef NETHER
        float c = 0.12; float b = 0.08; float o = 0.6;
    #elif defined END
        float c = 0.08; float b = 0.05; float o = 0.5;
    #else
        float c = 0.08 * rainMult; float b = 0.07 * rainMult; float o = 0.6 + rainMult * 0.1;
    #endif

    if(isEyeInWater >= 1){
        c = mix(c * 1.44, c, waterVoid); b = mix(b * 1.44, b, waterVoid); o = mix(o * 1.44, o, waterVoid);
    }

    // Mist fog
    float mistFog = atmoFog(eyePlayerPos.y, worldPosY, eyePlayerPosLength, c, b) * o;
    color = mix(color, fogCol, mistFog * MIST_GROUND_FOG_BRIGHTNESS);

    // Border fog
    #ifdef BORDER_FOG
        float borderFog = getBorderFogAmount(eyePlayerPosLength / (1.0 + cloudMask * 0.6));
        color = color * (1.0 - borderFog) + fogCol * borderFog;
    #else
        color = color * (1.0 - skyMask) + fogCol * skyMask;
    #endif

    // Blindness fog
    float blindNessFog = exp(-eyePlayerPosLength * blindness);
    return color * blindNessFog;
}