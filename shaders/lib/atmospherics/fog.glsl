float atmoFog(float playerPosY, float worldPosY, float playerPosLength, float heightDensity, float fogDensity){
    float fogAmount = heightDensity * exp(-playerPosY * fogDensity) * (1.0 - exp(-playerPosLength * worldPosY * fogDensity)) / worldPosY;
    return min(fogAmount, 1.0);
}

float getFogAmount(float nEyePlayerPosY, float eyePlayerPosLength){
    float waterVoid = smootherstep(nEyePlayerPosY + (eyeBrightFact - 0.6));
    #ifdef NETHER
        float fogFar = 32.0;
        fogFar = max(far - fogFar, 0.0);
        float fogNear = fogFar * 0.64;
    #elif defined END
        float fogFar = 16.0;
        fogFar = max(far - fogFar, 0.0);
        float fogNear = fogFar * 0.72;
    #else
        float fogFar = 16.0;
        fogFar = max(far - fogFar, 0.0); // * (1.0 - skyMask) + 160.0 * skyMask;
        float fogNear = fogFar * 0.72; // * (1.0 - skyMask) + 128.0 * skyMask;
    #endif
    if(isEyeInWater >= 1){
        fogNear = mix(near * 0.64, fogNear, waterVoid);
        fogFar = mix(far * 0.64, fogFar, waterVoid);
    }

    return smoothstep(fogNear, fogFar, eyePlayerPosLength);
}

vec3 getFog(vec3 eyePlayerPos, vec3 color, vec3 fogCol, float worldPosY){
    vec3 nEyePlayerPos = normalize(eyePlayerPos);
    float eyePlayerPosLength = length(eyePlayerPos);

    #ifdef NETHER
        float c = 0.12; float b = 0.08; float o = 0.4;
    #elif defined END
        float c = 0.08; float b = 0.05; float o = 0.5;
    #else
        float c = 0.08; float b = 0.07; float o = 0.6;
    #endif
    if(isEyeInWater >= 1){
        c *= 1.44; b *= 1.44; o *= 1.24;
    }

    float fogAmount = getFogAmount(nEyePlayerPos.y, eyePlayerPosLength);
    float mistFog = atmoFog(eyePlayerPos.y, worldPosY, eyePlayerPosLength, c, b) * o;
    color = mix(color, pow(fogCol, vec3(1.0 / 4.0) * MIST_GROUND_FOG_BRIGHTNESS), mistFog);
    
    return color * (1.0 - fogAmount) + fogCol * fogAmount;
}