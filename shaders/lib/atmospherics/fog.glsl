float atmoFog(positionVectors posVec, float viewPosLength){
    #ifdef NETHER
        float c = 0.16; float b = 0.08; float o = 0.4;
    #elif defined END
        float c = 0.1; float b = 0.05; float o = 0.5;
    #else
        float c = 0.081; float b = 0.081; float o = 0.63;
    #endif
    if(isEyeInWater >= 1){
        c *= 1.44; b *= 1.44; o *= 1.24;
    }
    float fogAmount = c * exp(-posVec.viewPos.y * b) * (1.0 - exp(-viewPosLength * posVec.worldPos.y * b)) / posVec.worldPos.y;
    return saturate(fogAmount) * o;
}

float getFogAmount(positionVectors posVec, float viewPosLength){
    vec3 nViewPos = normalize(posVec.viewPos);
    float waterVoid = smoothstep(0.9 - eyeBrightFact, 1.2 - eyeBrightFact, nViewPos.y);
    float isSkyDepth = float(getDepth(posVec.st) == 1.0);
    float skyMask = max(getSkyMask(posVec.st) - isSkyDepth, 0.0);
    #ifdef NETHER
        float fogNear = 64.0; float fogFar = 16.0;
        fogNear = max(far - fogNear, 0.0);
        fogFar = max(far - fogFar, 0.0);
    #elif defined END
        float fogNear = 48.0; float fogFar = 16.0;
        fogNear = max(far - fogNear, 0.0);
        fogFar = max(far - fogFar, 0.0);
    #else
        float fogNear = 32.0; float fogFar = 16.0;
        fogNear = max(far - fogNear, 0.0) * (1.0 - skyMask) + 128.0 * skyMask;
        fogFar = max(far - fogFar, 0.0) * (1.0 - skyMask) + 160.0 * skyMask;
    #endif
    if(isEyeInWater >= 1){
        fogNear = mix(near * 0.64, fogNear, waterVoid);
        fogFar = mix(far * 0.64, fogFar, waterVoid);
    }

    return smoothstep(fogNear, fogFar, viewPosLength);
}

vec3 getFog(positionVectors posVec, vec3 color, vec3 fogCol){
    float viewPosLength = length(posVec.viewPos);

    float fogAmount = getFogAmount(posVec, viewPosLength);
    float mistFog = atmoFog(posVec, viewPosLength);
    color = mix(color, sqrt(fogCol), mistFog);
    
    return color * (1.0 - fogAmount) + fogCol * fogAmount;
}