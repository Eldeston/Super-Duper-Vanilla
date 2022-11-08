#ifdef WORLD_HORIZON
#endif

#if WORLD_SUN_MOON != 0
    float getSunMoonShape(in vec2 pos){
        #if SUN_MOON_TYPE == 1
            // Round sun and moon
            return min(1.0, exp2(-(length(pos) - WORLD_SUN_MOON_SIZE) * 256.0));
        #else
            // Default sun and moon
            return min(1.0, exp2(-(pow(abs(pos.x * pos.x * pos.x) + abs(pos.y * pos.y * pos.y), 0.33333333) - WORLD_SUN_MOON_SIZE) * 256.0));
        #endif
    }
#endif

#if TIMELAPSE_MODE != 0
    uniform float animationFrameTime;

    #define ANIMATION_FRAMETIME animationFrameTime
#else
    #define ANIMATION_FRAMETIME frameTimeCounter
#endif

#if defined STORY_MODE_CLOUDS && !defined FORCE_DISABLE_CLOUDS
    float cloudParallax(in vec2 start, in float time){
        // start * stepSize * depthSize = start * 0.125 * 0.08
        vec2 end = start * 0.01;
        
        // Move towards west
        start.x += time * 0.125;
        for(int i = 0; i < 8; i++){
            if(texelFetch(colortex4, ivec2(start) & 255, 0).a > ALPHA_THRESHOLD) return 1.0 - i * 0.125;
            start += end;
        }
        
        return 0.0;
    }
#endif

vec3 getSkyColor(in vec3 skyBoxCol, in vec3 nPlayerPos, in float LV, in bool isSky, in bool isReflection){
    vec3 finalCol = skyCol;

    #ifdef WORLD_SKY_GROUND
        finalCol.rg *= smoothen(saturate(1.0 + nPlayerPos.y * 4.0));
    #endif

    #if defined WORLD_HORIZON && defined WORLD_LIGHT
        finalCol += exp2((lightCol - abs(nPlayerPos.y) - 1.0) * 8.0);
    #endif

    if(isSky){
        // Sky box and vanila sun and moon blending
        finalCol = finalCol * max(vec3(0), 1.0 - skyBoxCol) + skyBoxCol;

        #ifdef STORY_MODE_CLOUDS
            #ifndef FORCE_DISABLE_CLOUDS
                float cloudHeightFade = nPlayerPos.y - 0.125 - rainStrength * 0.175;
                
                if(cloudHeightFade > 0.005){
                    vec2 planeUv = nPlayerPos.xz * (5.33333333 / nPlayerPos.y);

                    float clouds = cloudParallax(planeUv, ANIMATION_FRAMETIME);

                    #ifdef DYNAMIC_CLOUDS
                        float fade = smootherstep(sin(ANIMATION_FRAMETIME * FADE_SPEED) * 0.5 + 0.5);
                        float clouds2 = cloudParallax(-planeUv, -ANIMATION_FRAMETIME);
                        clouds = mix(mix(clouds, clouds2, fade), max(clouds, clouds2), rainStrength);
                    #endif

                    #ifdef WORLD_LIGHT
                        finalCol += lightCol * (clouds * min(1.0, cloudHeightFade * (4.0 - rainStrength * 3.2)));
                    #else
                        finalCol += clouds * min(1.0, cloudHeightFade * (4.0 - rainStrength * 3.2));
                    #endif
                }
            #endif
        #endif
    }

    #ifdef WORLD_LIGHT
        #if WORLD_SUN_MOON == 1
            finalCol += lightCol * pow(max(LV, 0.0) * 0.70710678, abs(nPlayerPos.y) + 1.0) * shdFade;
        #endif

        // Fake VL reflection
        if(isEyeInWater != 1 && isReflection){
            float heightFade = 1.0 - squared(max(0.0, nPlayerPos.y));
            heightFade = squared(squared(heightFade * heightFade));
            heightFade = (1.0 - heightFade) * rainStrength * 0.25 + heightFade;
            finalCol += lightCol * (heightFade * shdFade * VOL_LIGHT_BRIGHTNESS * 0.5);
        }
    #endif

    // Do a simple void gradient when underwater
    if(isEyeInWater == 1) return isReflection ? finalCol * max(0.0, nPlayerPos.y + eyeBrightFact - 1.0) : finalCol * smootherstep(max(0.0, nPlayerPos.y));
    return finalCol * max(0.0, (nPlayerPos.y + eyeBrightFact - 1.0) * (1.0 - eyeBrightFact) + eyeBrightFact);
}

vec3 getSkyRender(in vec3 nPlayerPos, in bool isSky, in bool isReflection){
    // If player is in water, return nothing if it's not the sky
    if(isEyeInWater == 1 && !isSky) return vec3(0);
    // If player is in lava, return fog color
    if(isEyeInWater == 2) return fogColor;

    return getSkyColor(vec3(0), nPlayerPos, dot(nPlayerPos, vec3(shadowModelView[0].z, shadowModelView[1].z, shadowModelView[2].z)), isSky, isReflection) + toLinear(AMBIENT_LIGHTING + nightVision * 0.5);
}

vec3 getSkyRender(in vec3 skyBoxCol, in vec3 nPlayerPos, in bool isSky){
    // If player is in water, return nothing if it's not the sky
    if(isEyeInWater == 1 && !isSky) return vec3(0);
    // If player is in lava, return fog color
    if(isEyeInWater == 2) return fogColor;
    
    vec3 nSkyPos = mat3(shadowModelView) * nPlayerPos;

    vec3 finalCol = getSkyColor(skyBoxCol, nPlayerPos, nSkyPos.z, isSky, false) + toLinear(AMBIENT_LIGHTING + nightVision * 0.5);

    #ifdef WORLD_LIGHT
        #if WORLD_SUN_MOON == 1 && SUN_MOON_TYPE != 2
            finalCol += (getSunMoonShape(nSkyPos.xy) * (1.0 - rainStrength) * SUN_MOON_INTENSITY * SUN_MOON_INTENSITY) * sRGBLightCol;
        #elif WORLD_SUN_MOON == 2
            float blackHole = min(1.0, 0.015625 / (16.0 - nSkyPos.z * 16.0 - WORLD_SUN_MOON_SIZE));
            if(blackHole <= 0) return vec3(0);

            nSkyPos.xy = rot2D(blackHole * PI2 * 16.0) * nSkyPos.xy;
            float rings = texture2DLod(noisetex, vec2(nSkyPos.x * blackHole, frameTimeCounter * 0.0009765625), 0).x;

            finalCol += ((rings * blackHole * 0.9 + blackHole * 0.1) * SUN_MOON_INTENSITY * SUN_MOON_INTENSITY) * lightCol;
        #endif
    #endif

    #ifdef WORLD_STARS
        // Star field generation
        vec2 starData = texelFetch(noisetex, ivec2((nSkyPos.xz * 256.0) / (abs(nSkyPos.y) + length(nSkyPos.xz))) & 255, 0).xy;
        finalCol += exp(starData.x * starData.y * 64.0 - 64.0) * (1.0 - rainStrength) * WORLD_STARS;
    #endif

    return finalCol;
}