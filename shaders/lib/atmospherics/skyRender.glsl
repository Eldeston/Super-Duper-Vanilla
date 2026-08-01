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

#if CLOUD_TYPE != 0 && !defined FORCE_DISABLE_CLOUDS && defined WORLD_LIGHT
    // Depth size / cloud steps
    const uint skyBoxCloudSteps = uint(SKYBOX_CLOUD_STEPS);
    const float cloudStepSize = 1.0 / skyBoxCloudSteps;
    const float depthSize = SKYBOX_CLOUD_DEPTH * cloudStepSize;

    vec2 cloudParallaxDynamic(in vec2 start, in vec2 cameraPos){
        // Apply depth size
        vec2 end = start * depthSize;

        // Scales and moves the clouds based on world position
        start += cameraPos * 0.0625;

        vec2 cloudData = vec2(0);
        for(uint i = 1u; i <= skyBoxCloudSteps; i++){
            vec2 cloudMap = texelFetch(colortex0, ivec2(start) & 255, 0).xy;
            if(cloudMap.x > 0.5) cloudData.x = i;
            if(cloudMap.y > 0.5) cloudData.y = i;
            start -= end;
        }

        return cloudData;
    }

    // Sky clouds render
    vec3 getSkyClouds(in vec3 nEyePlayerPos, in vec3 currSkyCol){
        float cloudHeightFade = nEyePlayerPos.y - 0.1;

        #ifdef FORCE_DISABLE_WEATHER
            cloudHeightFade *= 6.0;
        #else
            cloudHeightFade -= rainStrength * 0.2;
            cloudHeightFade *= 6.0 - rainStrength * 5.0;
        #endif

        if(cloudHeightFade <= 0) return currSkyCol;
        if(cloudHeightFade > 1) cloudHeightFade = 1.0;

        vec2 planeUv = nEyePlayerPos.xz * (6.0 / nEyePlayerPos.y);

        vec2 planePos = vec2(cameraPosition.x + fragmentFrameTime, cameraPosition.z);

        vec2 cloudData = cloudParallaxDynamic(planeUv, planePos);

        #ifdef DOUBLE_LAYERED_CLOUDS
            cloudData = max(cloudParallaxDynamic(planeUv * 2.0, planePos).yx * 0.25, cloudData);
        #endif

        #ifdef DYNAMIC_CLOUDS
            float fadeTime = saturate(sin(fragmentFrameTime * FADE_SPEED) * 0.8 + 0.5);

            float clouds = mix(mix(cloudData.x, cloudData.y, fadeTime), max(cloudData.x, cloudData.y), rainStrength);
        #else
            float clouds = mix(cloudData.x, max(cloudData.x, cloudData.y), rainStrength);
        #endif

        clouds *= cloudHeightFade * cloudStepSize;

        #ifdef FORCE_DISABLE_DAY_CYCLE
            currSkyCol += lightCol * clouds;
        #else
            currSkyCol += mix(moonCol, sunCol, dayCycleAdjust) * clouds;
        #endif

        return currSkyCol;
    }

#endif

vec3 getSkyBasic(in float nEyePlayerPosY, in float skyPosZ){
    // Apply ambient lighting with sky col (not realistic I know)
    vec3 currSkyCol = skyCol + toLinear(AMBIENT_LIGHTING + nightVision * 0.5);

    #ifdef WORLD_SKY_GROUND
        // currSkyCol.rg *= smoothen(saturate(1.0 + nEyePlayerPosY * 4.0));
        // if(nEyePlayerPosY < 0) currSkyCol *= smoothen(max(1.0 + nEyePlayerPosY / max(skyCol, 0.25), vec3(0.25)));
        if(nEyePlayerPosY < 0 && isEyeInWater == 0) currSkyCol *= exp2(-(nEyePlayerPosY * nEyePlayerPosY * 8.0) / max(skyCol * skyCol, vec3(0.125)));
    #endif

    #if defined WORLD_LIGHT && WORLD_SUN_MOON == 1
        #ifdef FORCE_DISABLE_DAY_CYCLE
            if(skyPosZ > 0) currSkyCol += lightCol * pow(skyPosZ * skyPosZ, abs(nEyePlayerPosY) + 1.0);
        #else
            float lightDiffuse = pow(skyPosZ * skyPosZ, abs(nEyePlayerPosY) + 1.0);
            float diffuseCycleAdjust = dayCycleAdjust * lightDiffuse;
            currSkyCol += skyPosZ > 0 ? sunCol * diffuseCycleAdjust : moonCol * (lightDiffuse - diffuseCycleAdjust);
        #endif
    #endif

    currSkyCol += lightningFlash;

    return currSkyCol;
}

// Sky half render
vec3 getSkyHalf(in vec3 nEyePlayerPos, in vec3 skyPos, in vec3 currSkyCol){
    #if (defined WORLD_AETHER && defined WORLD_LIGHT) || defined WORLD_STARS
        // Scaled by noise resolution
        vec2 skyCoordScale = skyPos.xy * 256.0;
    #endif

    #if defined WORLD_AETHER && defined WORLD_LIGHT
        int aetherAnimationSpeed = int(fragmentFrameTime * 8.0);

        // Looks complex, but all it does is move the noise texture in 3 different directions
        ivec2 aetherTexelCoord0 = ivec2(255 - skyCoordScale - aetherAnimationSpeed) & 255;
        ivec2 aetherTexelCoord1 = ivec2(aetherTexelCoord0.x, int(skyCoordScale.y - aetherAnimationSpeed) & 255);
        ivec2 aetherTexelCoord2 = ivec2(int(skyCoordScale.x - aetherAnimationSpeed) & 255, aetherTexelCoord0.y);

        vec3 aetherNoise = vec3(texelFetch(noisetex, aetherTexelCoord0, 0).z,
            texelFetch(noisetex, aetherTexelCoord1, 0).z,
            texelFetch(noisetex, aetherTexelCoord2, 0).z);

        currSkyCol += exp2(-abs(nEyePlayerPos.y) * 8.0) * cubed(aetherNoise * lightCol + sumOf(aetherNoise) * 0.66666666) * lightCol;
    #endif

    #ifdef WORLD_STARS
        // Star field generation
        vec2 starData = texelFetch(noisetex, ivec2(skyCoordScale / (abs(skyPos.z) + sqrt(1.0 - skyPos.z * skyPos.z))) & 255, 0).xy;
        float stars = exp(starData.x * starData.y * 64.0 - 64.0);

        #ifdef FORCE_DISABLE_WEATHER
            currSkyCol += stars * WORLD_STARS;
        #else
            currSkyCol += (1.0 - rainStrength) * stars * WORLD_STARS;
        #endif
    #endif

    return currSkyCol;
}

vec3 getSkyFogRender(in vec3 nEyePlayerPos){
    // If player is in water, return nothing if it's not the sky
    if(isEyeInWater == 1) return vec3(0);
    // If player is in lava, return fog color
    if(isEyeInWater == 2) return fogColor;

    // Get sky pos by shadow model view
    vec3 skyPos = mat3(shadowModelView) * nEyePlayerPos;

    #if defined WORLD_LIGHT && !defined FORCE_DISABLE_DAY_CYCLE
        // Flip if the sun has gone below the horizon
        if(dayCycle < 1) skyPos.xz = -skyPos.xz;
    #endif

    // Get basic sky simple color
    vec3 currSkyCol = getSkyBasic(nEyePlayerPos.y, skyPos.z);
    
    #if defined WORLD_AETHER && defined WORLD_LIGHT
        // Scaled by noise resolution
        vec2 skyCoordScale = skyPos.xy * 256.0;

        int aetherAnimationSpeed = int(fragmentFrameTime * 8.0);

        // Looks complex, but all it does is move the noise texture in 3 different directions
        ivec2 aetherTexelCoord0 = ivec2(255 - skyCoordScale - aetherAnimationSpeed) & 255;
        ivec2 aetherTexelCoord1 = ivec2(aetherTexelCoord0.x, int(skyCoordScale.y - aetherAnimationSpeed) & 255);
        ivec2 aetherTexelCoord2 = ivec2(int(skyCoordScale.x - aetherAnimationSpeed) & 255, aetherTexelCoord0.y);

        vec3 aetherNoise = vec3(texelFetch(noisetex, aetherTexelCoord0, 0).z,
            texelFetch(noisetex, aetherTexelCoord1, 0).z,
            texelFetch(noisetex, aetherTexelCoord2, 0).z);

        currSkyCol += exp2(-abs(nEyePlayerPos.y) * 8.0) * cubed(aetherNoise * lightCol + sumOf(aetherNoise) * 0.66666666) * lightCol;
    #endif

    // Do a simple void gradient calculation
    return currSkyCol * saturate(nEyePlayerPos.y + eyeBrightFact * 3.0 - 1.0);
}

// Fog color render
vec3 getSkyFogRender(in vec3 nEyePlayerPos, in vec3 skyPos, in vec3 currSkyCol){
    // If player is in water, return nothing if it's not the sky
    if(isEyeInWater == 1) return vec3(0);
    // If player is in lava, return fog color
    if(isEyeInWater == 2) return fogColor;

    #if defined WORLD_AETHER && defined WORLD_LIGHT
        // Scaled by noise resolution
        vec2 skyCoordScale = skyPos.xy * 256.0;

        int aetherAnimationSpeed = int(fragmentFrameTime * 8.0);

        // Looks complex, but all it does is move the noise texture in 3 different directions
        ivec2 aetherTexelCoord0 = ivec2(255 - skyCoordScale - aetherAnimationSpeed) & 255;
        ivec2 aetherTexelCoord1 = ivec2(aetherTexelCoord0.x, int(skyCoordScale.y - aetherAnimationSpeed) & 255);
        ivec2 aetherTexelCoord2 = ivec2(int(skyCoordScale.x - aetherAnimationSpeed) & 255, aetherTexelCoord0.y);

        vec3 aetherNoise = vec3(texelFetch(noisetex, aetherTexelCoord0, 0).z,
            texelFetch(noisetex, aetherTexelCoord1, 0).z,
            texelFetch(noisetex, aetherTexelCoord2, 0).z);

        currSkyCol += exp2(-abs(nEyePlayerPos.y) * 8.0) * cubed(aetherNoise * lightCol + sumOf(aetherNoise) * 0.66666666) * lightCol;
    #endif

    // Do a simple void gradient calculation
    return currSkyCol * saturate(nEyePlayerPos.y + eyeBrightFact * 3.0 - 1.0);
}

// Sky reflection
vec3 getSkyReflection(in vec3 reflectViewDir){
    // If player is in lava, return fog color
    if(isEyeInWater == 2) return fogColor;

    vec3 reflectPlayerDir = mat3(gbufferModelViewInverse) * reflectViewDir;

    // Rotate normalized player position to shadow space
    vec3 skyPos = mat3(shadowModelView) * reflectPlayerDir;

    #if defined WORLD_LIGHT && !defined FORCE_DISABLE_DAY_CYCLE
        // Flip if the sun has gone below the horizon
        if(dayCycle < 1) skyPos.xz = -skyPos.xz;
    #endif

    vec3 finalCol = getSkyHalf(reflectPlayerDir, skyPos, getSkyBasic(reflectPlayerDir.y, skyPos.z));

    // Skybox clouds should render in reflections when volumetrics are on
    #if CLOUD_TYPE != 0 && !defined FORCE_DISABLE_CLOUDS && defined WORLD_LIGHT
        finalCol = getSkyClouds(reflectPlayerDir, finalCol);
    #endif

    // Do a simple void gradient calculation when underwater
    if(isEyeInWater == 1) return finalCol * max(0.0, reflectPlayerDir.y + eyeBrightFact - 1.0);

    #ifdef WORLD_LIGHT
        // Fake VL reflection
        const float fakeVLBrightness = VOLUMETRIC_LIGHTING_STRENGTH * 0.5;
        float VLBrightness = fakeVLBrightness * shdFade;

        if(reflectPlayerDir.y > 0){
            float heightFade = squared(squared(squared(1.0 - squared(reflectPlayerDir.y))));

            #ifndef FORCE_DISABLE_WEATHER
                heightFade += (1.0 - heightFade) * rainStrength * 0.5;
            #endif

            VLBrightness *= heightFade;
        }
        
        finalCol += lightCol * VLBrightness;
    #endif

    return finalCol * saturate(reflectPlayerDir.y + eyeBrightFact * 3.0 - 1.0);
}

// Full sky render
vec3 getFullSkyRender(in vec3 nEyePlayerPos, in vec3 skyPos, in vec3 currSkyCol){
    // If player is in lava, return fog color
    if(isEyeInWater == 2) return fogColor;

    #ifdef WORLD_LIGHT
        #if WORLD_SUN_MOON == 1 && SUN_MOON_TYPE != 2
            // If current world uses shader sun and moon but not vanilla sun and moon
            #if SUN_MOON_TYPE == 1
                float sunMoonShape = getSunMoonShape(skyPos.z) * sunMoonIntensitySqrd;
            #else
                float sunMoonShape = getSunMoonShape(skyPos.xy) * sunMoonIntensitySqrd;
            #endif

            #ifndef FORCE_DISABLE_WEATHER
                #ifdef FORCE_DISABLE_DAY_CYCLE
                    currSkyCol += sRGBLightCol * (sunMoonShape - rainStrength * sunMoonShape);
                #else
                    currSkyCol += (skyPos.z > 0 ? sRGBSunCol : sRGBMoonCol) * (sunMoonShape - rainStrength * sunMoonShape);
                #endif
            #endif
        #elif WORLD_SUN_MOON == 2
            // If current world uses shader black hole
            const float blackHoleSize = 1024.0 - WORLD_SUN_MOON_SIZE * 64.0;
            float blackHole = blackHoleSize - skyPos.z * 1024.0;

            // If black hole return nothing
            if(blackHole <= 0) return vec3(0);
            blackHole = 1.0 / max(1.0, blackHole);

            // Distortion application
            const float rotationFactor = TAU * 16.0;
            skyPos.xy = rot2D(blackHole * rotationFactor) * skyPos.xy;

            float rings = textureLod(noisetex, vec2(skyPos.x * blackHole, fragmentFrameTime * 0.0009765625), 0).x;

            currSkyCol += ((rings * blackHole * 0.9 + blackHole * 0.1) * sunMoonIntensitySqrd) * lightCol;
        #endif
    #endif

    // Combine sky box color and sky half color
    currSkyCol = getSkyHalf(nEyePlayerPos, skyPos, currSkyCol);

    #if CLOUD_TYPE == 1 && !defined FORCE_DISABLE_CLOUDS && defined WORLD_LIGHT
        currSkyCol = getSkyClouds(nEyePlayerPos, currSkyCol);
    #endif

    // Do a simple void gradient calculation when underwater
    if(isEyeInWater == 1) return currSkyCol * saturate(nEyePlayerPos.y * 1.66666667 - 0.16666667);
    return currSkyCol * saturate(nEyePlayerPos.y + eyeBrightFact * 3.0 - 1.0);
}