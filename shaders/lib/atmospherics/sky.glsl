float getStarShape(vec2 st, float size){
    return hermiteMix(0.032, 0.016, max2(abs(st)) / size);
}

float getSunMoonShape(vec3 pos){
    return smoothstep(0.0004, 0.0, length(cubed(pos.xy)));
}

float genStar(vec2 nSkyPos){
	vec3 starRand = getRandTex(nSkyPos, 1).rgb;
    vec2 starGrid = 0.5 * sin(starRand.xy * 12.0 + 128.0) - fract(nSkyPos * noiseTextureResolution) + 0.5;
    return getStarShape(starGrid, starRand.r * 0.9 + 0.3);
}

vec3 getSkyRender(vec3 playerPos, vec3 skyCol, vec3 lightCol, float skyMask, float skyDiffuseMask, float dither){
    #if defined NETHER || defined END
        return fogColor;
    #else
        // Get positions
        vec3 nPlayerPos = normalize(playerPos);
        vec3 nSkyPos = normalize(mat3(shadowProjection) * (mat3(shadowModelView) * playerPos));
        float offSet = 0.0;

        if(isEyeInWater >= 1){
            float waterVoid = smootherstep(nPlayerPos.y + (eyeBrightFact - 0.56));
            skyCol = mix(fogColor, skyCol, waterVoid);
            offSet = 0.25;
        }
        
        float skyFogGradient = smoothstep(-0.125, 0.125, nPlayerPos.y);
        float voidGradient = smoothstep(-0.1 - offSet, -0.025 + offSet, nPlayerPos.y) * 0.9;
        float lightRange = smootherstep(smootherstep(-nSkyPos.z * 0.56)) * (1.0 - newTwilight);
        float cloudFog = smootherstep(nPlayerPos.y * 2.0);

        // Get sun/moon
        float sunMoon = getSunMoonShape(nSkyPos) * voidGradient;

        // Get star
        vec2 starPos = 0.5 > abs(nSkyPos.y) ? vec2(atan(nSkyPos.x, nSkyPos.z), nSkyPos.y) * 0.25 : nSkyPos.xz * 0.333;
        float star = genStar(starPos * 0.128) * night * voidGradient;

        vec3 fogCol = skyCol * 0.75 * (1.0 - voidGradient) + voidGradient * skyCol;
        return (star + sunMoon * 5.0) * skyMask + (lightRange * lightCol * skyDiffuseMask) + mix(fogCol, skyCol, skyFogGradient);
    #endif
}