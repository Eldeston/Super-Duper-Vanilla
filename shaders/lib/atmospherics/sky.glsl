float getStarShape(vec2 st, float size){
    return smoothstep(0.032, 0.016, max2(abs(st)) / size);
}

float getSunMoonShape(vec3 pos){
    return smoothstep(0.0004, 0.0, length(cubed(pos.xy)));
}

float genStar(vec2 nSkyPos){
	vec3 starRand = getRandTex(nSkyPos, 1).rgb;
    vec2 starGrid = 0.5 * sin(starRand.xy * 12.0 + 128.0) - fract(nSkyPos * noiseTextureResolution) + 0.5;
    return getStarShape(starGrid, starRand.r * 0.9 + 0.3);
}

vec3 getSkyColor(vec3 nSkyPos, float nPlayerPosY, bool skyDiffuseMask){
    if(isEyeInWater == 2) return pow(fogColor, vec3(GAMMA));

    float lightRange = smoothen(-nSkyPos.z * 0.56) * (1.0 - newTwilight);

    #if defined USE_HORIZON_COL || defined USE_SUN_MOON
        #ifdef USE_SUN_MOON
            float horizon = smoothstep(-0.128, 0.128, nPlayerPosY);
        #endif
    #endif

    vec3 finalCol = skyCol;

    #ifdef USE_HORIZON_COL
        finalCol += USE_HORIZON_COL * squared(saturate(1.0 - abs(nPlayerPosY)));
    #endif

    if(isEyeInWater == 1){
        float waterVoid = smootherstep(nPlayerPosY + (eyeBrightFact - 0.64));
        finalCol = mix(fogColor * lightCol, skyCol, waterVoid);
        lightRange /= (1.0 - eyeBrightFact) + 2.0;
    }

    #ifdef USE_SUN_MOON
        if(skyDiffuseMask) finalCol += lightRange * lightCol * horizon;
    #endif

    return pow(finalCol, vec3(GAMMA));
}

vec3 getSkyRender(vec3 playerPos, bool skyDiffuseMask){
    return getSkyColor(normalize(mat3(shadowProjection) * (mat3(shadowModelView) * playerPos)), normalize(playerPos).y, skyDiffuseMask);
}

vec3 getSkyRender(vec3 playerPos, bool skyDiffuseMask, bool skyMask, bool sunMoonMask){
    vec3 nPlayerPos = normalize(playerPos);
    vec3 nSkyPos = normalize(mat3(shadowProjection) * (mat3(shadowModelView) * playerPos));

    vec3 finalCol = getSkyColor(nSkyPos, nPlayerPos.y, skyDiffuseMask);

    #ifdef USE_SUN_MOON
        if(sunMoonMask) finalCol += getSunMoonShape(nSkyPos) * 6.4 * lightCol;
    #endif

    #ifdef USE_STARS_COL
        if(skyMask){
            // Stars
            vec2 starPos = 0.5 > abs(nSkyPos.y) ? vec2(atan(nSkyPos.x, nSkyPos.z), nSkyPos.y) * 0.25 : nSkyPos.xz * 0.333;
            finalCol = max(finalCol, USE_STARS_COL * genStar(starPos * 0.128));
        }
    #endif

    return finalCol;
}