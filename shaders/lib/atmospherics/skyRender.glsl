#ifdef WORLD_AETHER
#endif

// Round sun and moon
float getSunMoonShape(in float skyPosZ){
    return min(1.0, exp2((WORLD_SUN_MOON_SIZE - sqrt(1.0 - skyPosZ * skyPosZ)) * 256.0));
}

// Default sun and moon
float getSunMoonShape(in vec2 skyPos){
    return min(1.0, exp2((WORLD_SUN_MOON_SIZE - pow(abs(skyPos.x * skyPos.x * skyPos.x) + abs(skyPos.y * skyPos.y * skyPos.y), 0.33333333)) * 256.0));
}

#if TIMELAPSE_MODE != 0
    uniform float animationFrameTime;

    #define ANIMATION_FRAMETIME animationFrameTime
#else
    #define ANIMATION_FRAMETIME frameTimeCounter
#endif

#if defined STORY_MODE_CLOUDS && !defined FORCE_DISABLE_CLOUDS
    int cloudParallax(in vec2 start, in float time){
        // start * stepSize * depthSize = start * 0.125 * 0.08
        vec2 end = start * 0.01;

        // Move towards west
        start.x += time;

        int cloudData = 0;
        for(int i = 0; i < 8; i++){
            if(texelFetch(colortex4, ivec2(start) & 255, 0).x < 0.5) cloudData = i;
            start -= end;
        }

        return cloudData;
    }

    vec3 cloudParallaxDynamic(in vec2 start, in float time){
        // start * stepSize * depthSize = start * 0.125 * 0.08
        vec2 end = start * 0.01;

        // Move towards west
        start.x += time;

        vec2 cloudData = vec2(0);
        for(int i = 0; i < 8; i++){
            vec2 cloudMap = texelFetch(colortex4, ivec2(start) & 255, 0).xy;
            if(cloudMap.x < 0.5) cloudData.x = i;
            if(cloudMap.y < 0.5) cloudData.y = i;
            start -= end;
        }

        return vec3(cloudData, maxOf(cloudData));
    }
#endif

// Sky basic render
vec3 getSkyBasic(in vec2 skyCoordScale, in float nEyePlayerPosY, in float skyPosZ){
    // Apply ambient lighting with sky col (not realistic I know)
    vec3 finalCol = skyCol + toLinear(AMBIENT_LIGHTING + nightVision * 0.5);

    #ifdef WORLD_SKY_GROUND
        finalCol.rg *= smoothen(saturate(1.0 + nEyePlayerPosY * 4.0));
    #endif

    #ifdef WORLD_LIGHT
        #ifdef WORLD_AETHER
            int aetherAnimationSpeed = int(frameTimeCounter * 8.0);

            // Looks complex, but all it does is move the noise texture in 3 different directions
            ivec2 aetherTexelCoord0 = ivec2(255 - skyCoordScale - aetherAnimationSpeed) & 255;
            ivec2 aetherTexelCoord1 = ivec2(aetherTexelCoord0.x, int(skyCoordScale.y - aetherAnimationSpeed) & 255);
            ivec2 aetherTexelCoord2 = ivec2(int(skyCoordScale.x - aetherAnimationSpeed) & 255, aetherTexelCoord0.y);

            vec3 aetherNoise = vec3(texelFetch(noisetex, aetherTexelCoord0, 0).z,
                texelFetch(noisetex, aetherTexelCoord1, 0).z,
                texelFetch(noisetex, aetherTexelCoord2, 0).z);

            finalCol += exp2(-abs(nEyePlayerPosY) * 8.0) * cubed(aetherNoise * lightCol + sumOf(aetherNoise) * 0.66666666) * lightCol;
        #endif

        #if WORLD_SUN_MOON == 1
            #ifdef FORCE_DISABLE_DAY_CYCLE
                if(skyPosZ > 0) finalCol += lightCol * pow(skyPosZ * skyPosZ, abs(nEyePlayerPosY) + 1.0);
            #else
                float lightDiffuse = pow(skyPosZ * skyPosZ, abs(nEyePlayerPosY) + 1.0);
                float diffuseCycleAdjust = dayCycleAdjust * lightDiffuse;
                finalCol += skyPosZ > 0 ? sunCol * diffuseCycleAdjust : moonCol * (lightDiffuse - diffuseCycleAdjust);
            #endif
        #endif
    #endif

    #ifdef IS_IRIS
        finalCol += lightningFlash;
    #endif

    return finalCol;
}

// Sky half render
vec3 getSkyHalf(in vec3 nEyePlayerPos, in vec3 skyPos){
    #if (defined WORLD_AETHER && defined WORLD_LIGHT) || defined WORLD_STARS
        // Scaled by noise resolution
        vec2 skyCoordScale = skyPos.xy * 256.0;
    #else
        vec2 skyCoordScale = vec2(0);
    #endif

    // Calculate basic sky color
    vec3 finalCol = getSkyBasic(skyCoordScale, nEyePlayerPos.y, skyPos.z);

    #if defined STORY_MODE_CLOUDS && defined WORLD_LIGHT && !defined FORCE_DISABLE_CLOUDS
        float cloudHeightFade = nEyePlayerPos.y - 0.125;

        #ifdef FORCE_DISABLE_WEATHER
            cloudHeightFade *= 4.0;
        #else
            cloudHeightFade -= rainStrength * 0.175;
            cloudHeightFade *= 4.0 - rainStrength * 3.2;
        #endif

        if(cloudHeightFade > 0.005){
            vec2 planeUv = nEyePlayerPos.xz * (5.33333333 / nEyePlayerPos.y);

            #ifdef DYNAMIC_CLOUDS
                float fade = saturate(sin(ANIMATION_FRAMETIME * FADE_SPEED) * 0.6 + 0.5);

                vec3 cloudData = cloudParallaxDynamic(planeUv, ANIMATION_FRAMETIME * 0.125);
                float clouds = mix(mix(cloudData.x, cloudData.y, fade), cloudData.z, rainStrength) * 0.125;
            #else
                float clouds = cloudParallax(planeUv, ANIMATION_FRAMETIME * 0.125) * 0.125;
            #endif

            #ifdef FORCE_DISABLE_DAY_CYCLE
                finalCol += lightCol * min(clouds, clouds * cloudHeightFade);
            #else
                finalCol += mix(moonCol, sunCol, dayCycleAdjust) * min(clouds, clouds * cloudHeightFade);
            #endif
        }
    #endif

    #ifdef WORLD_STARS
        // Star field generation
        vec2 starData = texelFetch(noisetex, ivec2(skyCoordScale / (abs(skyPos.z) + sqrt(1.0 - skyPos.z * skyPos.z))) & 255, 0).xy;
        float stars = exp(starData.x * starData.y * 64.0 - 64.0);

        #ifdef FORCE_DISABLE_WEATHER
            finalCol += stars * WORLD_STARS;
        #else
            finalCol += (1.0 - rainStrength) * stars * WORLD_STARS;
        #endif
    #endif

    return finalCol;
}

// Fog color render
vec3 getFogRender(in vec3 nEyePlayerPos){
    // If player is in water, return nothing if it's not the sky
    if(isEyeInWater == 1) return vec3(0);
    // If player is in lava, return fog color
    if(isEyeInWater == 2) return fogColor;

    // Rotate normalized player pos to shadow space
    vec3 skyPos = mat3(shadowModelView) * nEyePlayerPos;

    #if defined WORLD_LIGHT && !defined FORCE_DISABLE_DAY_CYCLE
        // Flip if the sun has gone below the horizon
        if(dayCycle < 1) skyPos.z = -skyPos.z;
    #endif

    #if defined WORLD_AETHER && defined WORLD_LIGHT
        // Scaled by noise resolution
        vec2 skyCoordScale = skyPos.xy * 256.0;
    #else
        vec2 skyCoordScale = vec2(0);
    #endif

    vec3 finalCol = getSkyBasic(skyCoordScale, nEyePlayerPos.y, skyPos.z);

    // Do a simple void gradient calculation
    return finalCol * saturate(nEyePlayerPos.y + eyeBrightFact * 2.0 - 1.0);
}

// Sky reflection
vec3 getSkyReflection(in vec3 nEyePlayerPos){
    // If player is in lava, return fog color
    if(isEyeInWater == 2) return fogColor;

    // Rotate normalized player pos to shadow space
    vec3 skyPos = mat3(shadowModelView) * nEyePlayerPos;

    #if defined WORLD_LIGHT && !defined FORCE_DISABLE_DAY_CYCLE
        // Flip if the sun has gone below the horizon
        if(dayCycle < 1) skyPos.z = -skyPos.z;
    #endif

    vec3 finalCol = getSkyHalf(nEyePlayerPos, skyPos);

    // Do a simple void gradient calculation when underwater
    if(isEyeInWater == 1) return finalCol * max(0.0, nEyePlayerPos.y + eyeBrightFact - 1.0);

    #ifdef WORLD_LIGHT
        // Fake VL reflection
        const float fakeVLBrightness = VOLUMETRIC_LIGHTING_STRENGTH * 0.5;
        float VLBrightness = fakeVLBrightness * shdFade;

        if(nEyePlayerPos.y > 0){
            float heightFade = 1.0 - squared(nEyePlayerPos.y);
            heightFade = squared(squared(heightFade * heightFade));

            #ifndef FORCE_DISABLE_WEATHER
                heightFade += (1.0 - heightFade) * rainStrength * 0.5;
            #endif

            finalCol += lightCol * (heightFade * VLBrightness);
        }
        else finalCol += lightCol * VLBrightness;
    #endif

    return finalCol * saturate(nEyePlayerPos.y + eyeBrightFact * 2.0 - 1.0);
}

// Full sky render
vec3 getFullSkyRender(in vec3 nEyePlayerPos, in vec3 skyBoxCol){
    // If player is in lava, return fog color
    if(isEyeInWater == 2) return fogColor;

    // Rotate normalized player pos to shadow space
    vec3 skyPos = mat3(shadowModelView) * nEyePlayerPos;

    // Use sky box color as base color
    vec3 finalCol = skyBoxCol;

    #ifdef WORLD_LIGHT
        #ifndef FORCE_DISABLE_DAY_CYCLE
            // Flip if the sun has gone below the horizon
            if(dayCycle < 1) skyPos.z = -skyPos.z;
        #endif

        #if WORLD_SUN_MOON == 1 && SUN_MOON_TYPE != 2
            // If current world uses shader sun and moon but not vanilla sun and moon
            #if SUN_MOON_TYPE == 1
                float sunMoonShape = getSunMoonShape(skyPos.z) * SUN_MOON_INTENSITY * SUN_MOON_INTENSITY;
            #else
                float sunMoonShape = getSunMoonShape(skyPos.xy) * SUN_MOON_INTENSITY * SUN_MOON_INTENSITY;
            #endif

            #ifndef FORCE_DISABLE_WEATHER
                #ifdef FORCE_DISABLE_DAY_CYCLE
                    finalCol += sRGBLightCol * (sunMoonShape - rainStrength * sunMoonShape);
                #else
                    finalCol += (skyPos.z > 0 ? sRGBSunCol : sRGBMoonCol) * (sunMoonShape - rainStrength * sunMoonShape);
                #endif
            #endif
        #elif WORLD_SUN_MOON == 2
            // If current world uses shader black hole
            const float blackHoleSize = 1024.0 - WORLD_SUN_MOON_SIZE * 64.0;
            float blackHole = blackHoleSize - skyPos.z * 1024.0;

            // If black hole return nothing
            if(blackHole <= 0) return vec3(0);
            blackHole = 1.0 / max(1.0, blackHole);

            const float rotationFactor = TAU * 16.0;
            skyPos.xy = rot2D(blackHole * rotationFactor) * skyPos.xy;
            float rings = textureLod(noisetex, vec2(skyPos.x * blackHole, frameTimeCounter * 0.0009765625), 0).x;

            finalCol += ((rings * blackHole * 0.9 + blackHole * 0.1) * SUN_MOON_INTENSITY * SUN_MOON_INTENSITY) * lightCol;
        #endif
    #endif

    // Combine sky box color and sky half color
    finalCol += getSkyHalf(nEyePlayerPos, skyPos);

    // Do a simple void gradient calculation when underwater
    if(isEyeInWater == 1) return finalCol * saturate(nEyePlayerPos.y * 1.66666667 - 0.16666667);
    return finalCol * saturate(nEyePlayerPos.y + eyeBrightFact * 2.0 - 1.0);
}