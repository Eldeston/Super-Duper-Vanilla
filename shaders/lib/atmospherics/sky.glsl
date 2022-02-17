#if USE_SUN_MOON != 0
    float getSunMoonShape(vec2 pos){
        #if SUN_MOON_TYPE == 1
            // Round sun and moon
            return min(1.0, exp2(-(length(pos) - 0.075) * 256.0));
        #else
            // Default sun and moon
            return min(1.0, exp2(-(pow(abs(pos.x * pos.x * pos.x) + abs(pos.y * pos.y * pos.y), 0.333) - 0.075) * 256.0));
        #endif
    }
#endif

#ifdef USE_STARS_COL
    float getStarShape(vec2 st, float size){
        return smoothstep(0.032, 0.016, max2(abs(st)) / size);
    }

    float genStar(vec2 nSkyPos){
        vec2 starRand = getRand2(nSkyPos);
        vec2 starGrid = 0.5 * sin(starRand * 12.0 + 256.0) - fract(nSkyPos * noiseTextureResolution) + 0.5;
        return getStarShape(starGrid, starRand.x * 0.9 + 0.3);
    }
#endif

#if defined STORY_MODE_CLOUDS && !defined FORCE_DISABLE_CLOUDS
    float cloudParallax(vec2 pos, float time, int steps){
        vec2 uv = pos / 48.0;
        float invSteps = 1.0 / steps;

        vec2 start = uv;
        vec2 end = start * 0.08 * invSteps;
        float cloudSpeed = time * 0.0004;

        for(int i = 0; i < steps; i++){
            start += end;
            if(texture2D(colortex4, start + vec2(cloudSpeed, 0)).a > ALPHA_THRESHOLD) return 1.0 - i * invSteps;
        }
        
        return 0.0;
    }
#endif

vec3 getSkyColor(vec3 nPlayerPos, float nSkyPosZ, bool skyMask){
    if(isEyeInWater == 2) return pow(fogColor, vec3(GAMMA));

    #ifdef WORLD_SKY_GROUND
        vec3 finalCol = skyCol * vec2(1.0 - smoothen((-nPlayerPos.y * 4.0) / (isEyeInWater * 2.56 + rainMult)), 1).xxy;
    #else
        vec3 finalCol = skyCol;
    #endif

    #ifdef USE_HORIZON_COL
        finalCol += USE_HORIZON_COL * squared(1.0 - abs(nPlayerPos.y));
    #endif
    
    #ifdef STORY_MODE_CLOUDS
        #ifndef FORCE_DISABLE_CLOUDS
            if(skyMask){
                vec2 planeUv = nPlayerPos.xz / nPlayerPos.y;

                #ifdef CLOUD_FADE
                    float fade = smootherstep(sin(frameTimeCounter * FADE_SPEED) * 0.5 + 0.5);
                    float clouds = mix(cloudParallax(planeUv, frameTimeCounter, 8), cloudParallax(-planeUv, 1250.0 - frameTimeCounter, 8), fade);
                #else
                    float clouds = cloudParallax(planeUv, frameTimeCounter, 8);
                #endif

                #ifdef WORLD_LIGHT
                    finalCol += lightCol * (clouds * smootherstep(nPlayerPos.y * 2.0 - 0.125));
                #else
                    finalCol += clouds * smootherstep(nPlayerPos.y * 2.0 - 0.125);
                #endif
            }
        #endif
    #endif

    float voidGradient = smootherstep((nPlayerPos.y + eyeBrightFact - 0.81) * PI);
    if(isEyeInWater == 1) finalCol *= voidGradient;

    #if USE_SUN_MOON == 1 && defined WORLD_LIGHT
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

    vec3 finalCol = vec3(0);

    #if USE_SUN_MOON == 1 && SUN_MOON_TYPE != 2
        if(sunMoonMask) finalCol += getSunMoonShape(nSkyPos.xy) * SUN_MOON_INTENSITY * SUN_MOON_INTENSITY * sqrt(lightCol);
    #elif USE_SUN_MOON == 2
        if(sunMoonMask){
            float blackHole = saturate(0.01 / ((nSkyPos.z + 1.0) * 32.0 - 0.075));
            if(blackHole <= 0) return vec3(0);
            float ring0 = exp(-abs(length(vec2(nSkyPos.x, nSkyPos.y)) - 0.075) * 256.0);
            finalCol += blackHole * SUN_MOON_INTENSITY * SUN_MOON_INTENSITY * lightCol;
            nPlayerPos = mix(nPlayerPos, vec3(shadowModelView[0].z, shadowModelView[1].z, shadowModelView[2].z), blackHole);
            nSkyPos = mix(nSkyPos, vec3(shadowModelView[0].z, shadowModelView[1].z, shadowModelView[2].z), blackHole);
        }
    #endif

    finalCol += getSkyColor(nPlayerPos, nSkyPos.z, skyMask);

    #ifdef USE_STARS_COL
        if(skyMask){
            // Stars
            vec2 starPos = 0.5 > abs(nSkyPos.y) ? vec2(atan(nSkyPos.x, nSkyPos.z), nSkyPos.y) * 0.25 : nSkyPos.xz * 0.333;
            finalCol += USE_STARS_COL * genStar(starPos * 0.128);
        }
    #endif

    return finalCol;
}