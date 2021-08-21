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

vec3 getSkyRender(vec3 playerPos, vec3 inLightCol, float skyDiffuseMask, bool skyMask){
    if(isEyeInWater == 2) return pow(fogColor, vec3(GAMMA));

    vec3 nSkyPos = normalize(mat3(shadowProjection) * (mat3(shadowModelView) * playerPos));
    float lightRange = smoothen(-nSkyPos.z * 0.56) * (1.0 - newTwilight);

    #if defined USE_HORIZON || defined USE_SUN_MOON || defined USE_STARS
        float nPlayerPosY = normalize(playerPos).y;
        
        #if defined USE_SUN_MOON || defined USE_STARS
            float horizon = smoothstep(-0.1, 0.1, nPlayerPosY);
        #endif
    #endif

    vec3 finalCol = skyCol;

    #ifdef USE_HORIZON
        finalCol *= 1.0 + 2.0 * cubed(saturate(1.0 - abs(nPlayerPosY)));
    #endif

    if(isEyeInWater == 1){
        float waterVoid = smootherstep(normalize(playerPos).y + (eyeBrightFact - 0.64));
        finalCol = mix(toneSaturation(fogColor, 0.5) * (0.25 * (1.0 - eyeBrightFact) + eyeBrightFact), skyCol, waterVoid);
        lightRange /= (1.0 - eyeBrightFact) + 2.0;
    }

    #ifdef USE_SUN_MOON
        finalCol += (lightRange * skyDiffuseMask * horizon) * lightCol;

        if(skyMask) finalCol += getSunMoonShape(nSkyPos) * 6.4 * sqrt(inLightCol);
    #endif

    #ifdef USE_STARS
        if(skyMask){
            // Stars
            vec2 starPos = 0.5 > abs(nSkyPos.y) ? vec2(atan(nSkyPos.x, nSkyPos.z), nSkyPos.y) * 0.25 : nSkyPos.xz * 0.333;
            finalCol = max(finalCol, vec3(genStar(starPos * 0.128) * horizon * 0.75));
        }
    #endif

    return pow(finalCol, vec3(GAMMA));
}