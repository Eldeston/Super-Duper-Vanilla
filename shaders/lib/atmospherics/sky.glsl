float getStarShape(vec2 st, float size){
    return hermiteMix(0.032, 0.016, max2(abs(st)) / size);
}

float getSunMoonShape(vec3 pos){
    return smoothstep(0.0005, 0.00025, length(cubed(pos.xy)));
}

float genStar(vec2 nSkyPos){
	vec3 starRand = getRandTex(nSkyPos, 1).rgb;
    vec2 starGrid = 0.5 * sin(starRand.xy * 12.0 + 128.0) - fract(nSkyPos * noiseTextureResolution) + 0.5;
    float starShape = getStarShape(starGrid, starRand.r * 1.6 + 0.4);
    return starShape;
}

vec3 getSkyRender(positionVectors posVec, vec3 skyCol, vec3 lightCol){
    vec3 nViewPos = normalize(posVec.viewPos);
    if(isEyeInWater >= 1){
        float waterVoid = smootherstep(nViewPos.y + (eyeBrightFact - 0.56));
        skyCol = mix(fogColor * 0.72, skyCol, waterVoid);
    }
    #ifdef NETHER
        return fogColor;
    #elif defined END
        return fogColor;
    #else
        float isSkyDepth = float(getDepth(posVec.st) == 1.0);
        vec3 nSkyPos = normalize(mat3(shadowProjection) * (mat3(shadowModelView) * posVec.viewPos));
        float skyFogGradient = smoothstep(-0.125, 0.125, nViewPos.y);
        float voidGradient = smoothstep(-0.4, 0.0, nViewPos.y);
        // Instead of calculating the dot of the viewPos and lightPos, we get the skyPos' z channel
        // float lightDot = smootherstep(dot(nViewPos, nLightPos) * 0.625);
        float lightDot = smootherstep(-nSkyPos.z * 0.56);

        float lightRange = lightDot * (1.0 - newTwilight);

        float sunMoon = getSunMoonShape(nSkyPos) * voidGradient;

        vec2 starPos = 0.5 > abs(nSkyPos.y) ? vec2(atan(nSkyPos.x, nSkyPos.z), nSkyPos.y) * 0.25 : nSkyPos.xz * 0.333;
        float star = genStar(starPos * 0.128) * night * voidGradient;

        float newSkyData = max(star, sunMoon) * isSkyDepth;

        vec3 fogCol = skyCol * (0.5 * (1.0 - voidGradient) + voidGradient) * 0.75;

        return mix(mix(mix(fogCol, skyCol, skyFogGradient), lightCol + cubed(lightRange) * 0.25, lightRange), lightCol + newSkyData, newSkyData);
    #endif
}