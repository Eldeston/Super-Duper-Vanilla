float getStarShape(vec2 st, float size){
    return smoothstep(0.032, 0.016, max2(abs(st)) / size);
}

float getSunMoonShape(vec2 pos){
    return exp2(-(pow(abs(pos.x * pos.x * pos.x) + abs(pos.y * pos.y * pos.y), 0.333) - 0.075) * 128.0);
}

float genStar(vec2 nSkyPos){
	vec2 starRand = getRandTex(nSkyPos, 1).xy;
    vec2 starGrid = 0.5 * sin(starRand * 12.0 + 128.0) - fract(nSkyPos * noiseTextureResolution) + 0.5;
    return getStarShape(starGrid, starRand.x * 0.9 + 0.3);
}

#if defined STORY_MODE_CLOUDS && !defined FORCE_DISABLE_CLOUDS
    float cloudParallax(vec2 pos, float time, int steps){
        vec2 uv = pos / 48.0;
        float invSteps = 1.0 / steps;

        vec2 start = uv;
        vec2 end = start * 0.08 * invSteps;
        float cloudSpeed = time * 0.0004;

        for(int i = 0; i < steps; i++){
            start += end;
            if(texture2D(colortex7, start + vec2(cloudSpeed, 0)).a > 0.05) return 1.0 - i * invSteps;
        }
        
        return 0;
    }
#endif

vec3 getSkyColor(vec3 nPlayerPos, float nSkyPosZ, bool skyMask){
    if(isEyeInWater == 2) return pow(fogColor, vec3(2.2));

    vec2 planeUv = nPlayerPos.xz / nPlayerPos.y;

    #ifdef SKY_GROUND_COL
        float c = 8.0 / (isEyeInWater * 2.56 + rainMult);
        vec3 finalCol = mix(skyCol, SKY_GROUND_COL * (skyCol + lightCol + ambientLighting), smoothen((-nPlayerPos.y) * c));
    #else
        vec3 finalCol = skyCol;
    #endif

    #ifdef USE_HORIZON_COL
        finalCol += USE_HORIZON_COL * squared(1.0 - abs(nPlayerPos.y));
    #endif
    
    #ifdef STORY_MODE_CLOUDS
        #ifndef FORCE_DISABLE_CLOUDS
            if(skyMask){
                #ifdef CLOUD_FADE
                    float fade = smootherstep(sin(frameTimeCounter * FADE_SPEED) * 0.5 + 0.5);
                    float clouds = mix(cloudParallax(planeUv, frameTimeCounter, 8), cloudParallax(-planeUv, 1250.0 - frameTimeCounter, 8), fade);
                #else
                    float clouds = cloudParallax(planeUv, frameTimeCounter, 8);
                #endif

                #ifdef ENABLE_LIGHT
                    finalCol += lightCol * (clouds * clouds * smootherstep(nPlayerPos.y * 2.0 - 0.125));
                #else
                    finalCol += clouds * clouds * smootherstep(nPlayerPos.y * 2.0 - 0.125);
                #endif
            }
        #endif
    #endif

    float voidGradient = smootherstep((nPlayerPos.y + eyeBrightFact - 0.9) * PI);
    if(isEyeInWater == 1) finalCol *= voidGradient;

    #if defined USE_SUN_MOON && defined ENABLE_LIGHT
        finalCol += lightCol * pow(max(-nSkyPosZ * 0.5, 0.0), abs(nPlayerPos.y) + 1.0);
    #endif
    
    return finalCol * (isEyeInWater == 0 ? voidGradient * (1.0 - eyeBrightFact) + eyeBrightFact : 1.0) + ambientLighting;
}

vec3 getSkyRender(vec3 playerPos, bool skyMask){
    return getSkyColor(normalize(playerPos), normalize(mat3(shadowProjection) * (mat3(shadowModelView) * playerPos)).z, skyMask);
}

vec3 getSkyRender(vec3 playerPos, bool skyMask, bool sunMoonMask){
    vec3 nPlayerPos = normalize(playerPos);
    vec3 nSkyPos = normalize(mat3(shadowProjection) * (mat3(shadowModelView) * playerPos));

    vec3 finalCol = getSkyColor(nPlayerPos, nSkyPos.z, skyMask);

    #if defined USE_SUN_MOON && !defined VANILLA_SUN_MOON
        if(sunMoonMask) finalCol += getSunMoonShape(nSkyPos.xy) * 4.0;
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