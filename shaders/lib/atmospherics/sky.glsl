#ifdef WORLD_LIGHT
    #if WORLD_SUN_MOON == 1
        uniform float shdFade;
    #endif
#endif

#if WORLD_SUN_MOON != 0
    float getSunMoonShape(vec2 pos){
        #if SUN_MOON_TYPE == 1
            // Round sun and moon
            return min(1.0, exp2(-(length(pos) - 0.1) * 256.0));
        #else
            // Default sun and moon
            return min(1.0, exp2(-(pow(abs(pos.x * pos.x * pos.x) + abs(pos.y * pos.y * pos.y), 0.333) - 0.1) * 256.0));
        #endif
    }
#endif

#if defined STORY_MODE_CLOUDS && !defined FORCE_DISABLE_CLOUDS
    #if TIMELAPSE_MODE != 0
        uniform float animationFrameTime;
        
        #define ANIMATION_FRAMETIME animationFrameTime
    #else
        #define ANIMATION_FRAMETIME frameTimeCounter
    #endif

    float cloudParallax(vec2 start, float time){
        // start * stepSize * depthSize = start * 0.125 * 0.08
        vec2 end = start * 0.01;
        
        // Move towards west
        start.x += time * 0.0004;
        for(int i = 0; i < 8; i++){
            if(texture2D(colortex4, start).a > ALPHA_THRESHOLD) return 1.0 - i * 0.125;
            start += end;
        }
        
        return 0.0;
    }
#endif

vec3 getSkyColor(vec3 skyBoxCol, vec3 sRGBLightCol, vec3 nPlayerPos, float LV, bool isSky){
    // If player is in lava, return fog color
    if(isEyeInWater == 2) return pow(fogColor, vec3(GAMMA));

    #ifdef WORLD_LIGHT
        vec3 lightColLinear = pow(sRGBLightCol, vec3(GAMMA));
    #endif

    #ifdef WORLD_SKY_GROUND
        vec3 finalCol = pow(SKY_COL_DATA_BLOCK, vec3(GAMMA)) * vec2(smoothstep(1.0, 0.0, (-nPlayerPos.y * 4.0) / (rainStrength * PI + 1.0)), 1).xxy;
    #else
        vec3 finalCol = pow(SKY_COL_DATA_BLOCK, vec3(GAMMA));
    #endif

    #ifdef WORLD_HORIZONCOL
        finalCol += WORLD_HORIZONCOL * cubed(1.0 - abs(nPlayerPos.y));
    #endif

    if(isSky){
        // Sky box and vanila sun and moon blending
        finalCol = finalCol * max(vec3(0), 1.0 - skyBoxCol) + skyBoxCol;

        #ifdef STORY_MODE_CLOUDS
            #ifndef FORCE_DISABLE_CLOUDS
                float cloudHeightFade = nPlayerPos.y - 0.125;
                
                if(cloudHeightFade > 0.005){
                    vec2 planeUv = nPlayerPos.xz / (nPlayerPos.y * 48.0);

                    float clouds = cloudParallax(planeUv, ANIMATION_FRAMETIME);

                    #ifdef DYNAMIC_CLOUDS
                        float fade = smootherstep(sin(ANIMATION_FRAMETIME * FADE_SPEED) * 0.5 + 0.5);
                        float clouds2 = cloudParallax(-planeUv, 1250.0 - ANIMATION_FRAMETIME);
                        clouds = mix(mix(clouds, clouds2, fade), max(clouds, clouds2), rainStrength);
                    #endif

                    #ifdef WORLD_LIGHT
                        finalCol += lightColLinear * (clouds * min(1.0, cloudHeightFade * 4.0));
                    #else
                        finalCol += clouds * min(1.0, cloudHeightFade * 4.0);
                    #endif
                }
            #endif
        #endif
    }

    #if WORLD_SUN_MOON == 1 && defined WORLD_LIGHT
        finalCol += lightColLinear * pow(max(LV, 0.0) * 0.75, abs(nPlayerPos.y) + 1.0) * shdFade;
    #endif

    float voidGradient = saturate((nPlayerPos.y + eyeBrightFact - 1.0) * PI2);
    return finalCol * (isEyeInWater == 1 ? voidGradient : voidGradient * (1.0 - eyeBrightFact) + eyeBrightFact) + pow(AMBIENT_LIGHTING + nightVision * 0.5, GAMMA);
}

vec3 getSkyRender(vec3 skyBoxCol, vec3 sRGBLightCol, vec3 nPlayerPos, bool isSky){
    return getSkyColor(skyBoxCol, sRGBLightCol, nPlayerPos, dot(nPlayerPos, vec3(shadowModelView[0].z, shadowModelView[1].z, shadowModelView[2].z)), isSky);
}

vec3 getSkyRender(vec3 skyBoxCol, vec3 sRGBLightCol, vec3 nPlayerPos, bool isSky, bool isSunMoon){
    vec3 nSkyPos = mat3(shadowModelView) * nPlayerPos;

    vec3 finalCol = getSkyColor(skyBoxCol, sRGBLightCol, nPlayerPos, nSkyPos.z, isSky);

    // If it's not the sky, return the base sky color
    if(!isSky) return finalCol;

    #ifdef WORLD_LIGHT
        #if WORLD_SUN_MOON == 1 && SUN_MOON_TYPE != 2
            if(isSunMoon) finalCol += (getSunMoonShape(nSkyPos.xy) * (1.0 - rainStrength) * SUN_MOON_INTENSITY * SUN_MOON_INTENSITY) * sRGBLightCol;
        #elif WORLD_SUN_MOON == 2
            if(isSunMoon){
                float blackHole = min(1.0, 0.005 / ((1.0 - nSkyPos.z) * 32.0 - 0.1));
                if(blackHole <= 0) return vec3(0);
                finalCol += blackHole * SUN_MOON_INTENSITY * SUN_MOON_INTENSITY * sRGBLightCol;
                nPlayerPos = mix(nPlayerPos, vec3(shadowModelView[0].z, shadowModelView[1].z, shadowModelView[2].z), blackHole);
                nSkyPos = mix(nSkyPos, vec3(shadowModelView[0].z, shadowModelView[1].z, shadowModelView[2].z), blackHole);
            }
        #endif
    #endif

    #ifdef WORLD_STARS
        // Star field generation
        vec2 starData = texture2D(noisetex, nSkyPos.xz / (abs(nSkyPos.y) + length(nSkyPos.xz))).xy;
        if(starData.x * starData.y > 0.9) finalCol += (1.0 - rainStrength) * WORLD_STARS;
    #endif

    return finalCol;
}