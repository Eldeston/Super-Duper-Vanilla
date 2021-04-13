float atmoFog(positionVectors posVec, float playerPosLength){
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
    float fogAmount = c * exp(-posVec.playerPos.y * b) * (1.0 - exp(-playerPosLength * posVec.worldPos.y * b)) / posVec.worldPos.y;
    return saturate(fogAmount) * o;
}

float getFogAmount(positionVectors posVec, float playerPosLength){
    vec3 nPlayerPos = normalize(posVec.playerPos);
    float waterVoid = smootherstep(nPlayerPos.y + (eyeBrightFact - 0.6));
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

    return smoothstep(fogNear, fogFar, playerPosLength);
}

vec3 getFog(positionVectors posVec, vec3 color, vec3 fogCol){
    float playerPosLength = length(posVec.playerPos);

    float fogAmount = getFogAmount(posVec, playerPosLength);
    float mistFog = atmoFog(posVec, playerPosLength);
    color = mix(color, sqrt(fogCol), mistFog);
    
    return color * (1.0 - fogAmount) + fogCol * fogAmount;
}