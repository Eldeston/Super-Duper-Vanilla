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

vec3 getSkyRender(vec3 playerPos, vec3 skyCol, vec3 lightCol, float skyMask, float skyDiffuseMask, float dirLightMask){
    #if defined USE_CUSTOM_FOGCOL || defined USE_VANILLA_FOGCOL
        return pow(skyCol, vec3(GAMMA));
    #else
        // Get positions
        vec3 nEyePlayerPos = normalize(playerPos);
        vec3 nSkyPos = normalize(mat3(shadowProjection) * (mat3(shadowModelView) * playerPos));
        float lightRange = smootherstep(-nSkyPos.z * 0.56) * (1.0 - newTwilight);

        if(isEyeInWater >= 1){
            float waterVoid = smootherstep(nEyePlayerPos.y + (eyeBrightFact - 0.64));
            skyCol = mix(toneSaturation(fogColor, 0.5) * (0.25 * (1.0 - eyeBrightFact) + eyeBrightFact), skyCol, waterVoid);
            lightRange /= (1.0 - eyeBrightFact) + isEyeInWater + 1.0;
        }

        // Get star pos
        vec2 starPos = 0.5 > abs(nSkyPos.y) ? vec2(atan(nSkyPos.x, nSkyPos.z), nSkyPos.y) * 0.25 : nSkyPos.xz * 0.333;

        float celestialBodies = (genStar(starPos * 0.128) * squared(1.0 - day) + getSunMoonShape(nSkyPos) * dirLightMask * 8.0) * skyMask;
        
        return pow(celestialBodies * sqrt(lightCol) + (lightRange * skyDiffuseMask) * lightCol + skyCol, vec3(GAMMA));
    #endif
}