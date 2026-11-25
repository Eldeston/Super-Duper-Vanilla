// Round sun and moon
float getSunMoonShape(in float skyPosZ){
    return min(1.0, exp2((WORLD_CELESTIAL_SIZE - sqrt(1.0 - skyPosZ * skyPosZ)) * 256.0));
}

// Default sun and moon
float getSunMoonShape(in vec2 skyPos){
    return min(1.0, exp2((WORLD_CELESTIAL_SIZE - pow(abs(skyPos.x * skyPos.x * skyPos.x) + abs(skyPos.y * skyPos.y * skyPos.y), 0.33333333)) * 256.0));
}

vec3 getSkyBasic(in float nEyePlayerPosY, in float skyPosZ){
    // Apply ambient lighting with sky col (not realistic I know)
    vec3 currSkyCol = skyCol;

    #if WORLD_SKYGROUND == 1
        // currSkyCol.rg *= smoothen(saturate(1.0 + nEyePlayerPosY * 4.0));
        // if(nEyePlayerPosY < 0) currSkyCol *= smoothen(max(1.0 + nEyePlayerPosY / max(skyCol, 0.25), vec3(0.25)));
        if(nEyePlayerPosY < 0 && isEyeInWater == 0) currSkyCol *= exp2(-(nEyePlayerPosY * nEyePlayerPosY * 8.0) / max(skyCol * skyCol, vec3(0.125)));
    #endif

    #if WORLD_LIGHT == 1 && WORLD_CELESTIAL == 1
        #if WORLD_DAYCYCLE == 0
            if(skyPosZ > 0) currSkyCol += lightCol * pow(skyPosZ * skyPosZ, abs(nEyePlayerPosY) + 1.0);
        #else
            float lightDiffuse = pow(skyPosZ * skyPosZ, abs(nEyePlayerPosY) + 1.0);
            float diffuseCycleAdjust = dayCycleAdjust * lightDiffuse;
            currSkyCol += skyPosZ > 0 ? sunCol * diffuseCycleAdjust : moonCol * (lightDiffuse - diffuseCycleAdjust);
        #endif
    #endif

    return currSkyCol;
}

// Sky half render
vec3 getSkyHalf(in vec3 nEyePlayerPos, in vec3 skyPos, in vec3 currSkyCol){
    #if WORLD_AETHER == 1 || WORLD_STARS == 1
        // Scaled by noise resolution
        vec2 skyCoordScale = skyPos.xy * 256.0;
    #endif

    #if WORLD_AETHER == 1
        int aetherAnimationSpeed = int(fragmentFrameTime * 8.0);

        // Looks complex, but all it does is move the noise texture in 3 different directions
        ivec2 aetherTexelCoord0 = ivec2(255 - skyCoordScale - aetherAnimationSpeed) & 255;
        ivec2 aetherTexelCoord1 = ivec2(aetherTexelCoord0.x, int(skyCoordScale.y - aetherAnimationSpeed) & 255);
        ivec2 aetherTexelCoord2 = ivec2(int(skyCoordScale.x - aetherAnimationSpeed) & 255, aetherTexelCoord0.y);

        vec3 aetherNoise = vec3(texelFetch(noisetex, aetherTexelCoord0, 0).z,
            texelFetch(noisetex, aetherTexelCoord1, 0).z,
            texelFetch(noisetex, aetherTexelCoord2, 0).z);

        #if WORLD_LIGHT == 1
            currSkyCol += exp2(-abs(nEyePlayerPos.y) * 8.0) * cubed(aetherNoise * lightCol + sumOf(aetherNoise) * 0.66666666) * lightCol;
        #else
            currSkyCol += exp2(-abs(nEyePlayerPos.y) * 8.0) * cubed(aetherNoise * sRGBSkyCol + sumOf(aetherNoise) * 0.66666666) * sRGBSkyCol;
        #endif
    #endif

    #if WORLD_STARS == 1
        // Star field generation
        vec2 starData = texelFetch(noisetex, ivec2(skyCoordScale / (abs(skyPos.z) + sqrt(1.0 - skyPos.z * skyPos.z))) & 255, 0).xy;
        float stars = exp(starData.x * starData.y * 64.0 - 64.0);

        #if WORLD_WEATHER == 1
            currSkyCol += (1.0 - rainStrength) * stars * worldStarIntensity();
        #else
            currSkyCol += stars * worldStarIntensity();
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

    #if WORLD_LIGHT == 1 && WORLD_DAYCYCLE == 1
        // Flip if the sun has gone below the horizon
        if(dayCycle < 1) skyPos.xz = -skyPos.xz;
    #endif

    // Get basic sky simple color
    vec3 currSkyCol = getSkyBasic(nEyePlayerPos.y, skyPos.z);
    
    #if WORLD_AETHER == 1
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

        #if WORLD_LIGHT == 1
            currSkyCol += exp2(-abs(nEyePlayerPos.y) * 8.0) * cubed(aetherNoise * lightCol + sumOf(aetherNoise) * 0.66666666) * lightCol;
        #else
            currSkyCol += exp2(-abs(nEyePlayerPos.y) * 8.0) * cubed(aetherNoise * sRGBSkyCol + sumOf(aetherNoise) * 0.66666666) * sRGBSkyCol;
        #endif
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

    #if WORLD_AETHER == 1
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
        
        #if WORLD_LIGHT == 1
            currSkyCol += exp2(-abs(nEyePlayerPos.y) * 8.0) * cubed(aetherNoise * lightCol + sumOf(aetherNoise) * 0.66666666) * lightCol;
        #else
            currSkyCol += exp2(-abs(nEyePlayerPos.y) * 8.0) * cubed(aetherNoise * sRGBSkyCol + sumOf(aetherNoise) * 0.66666666) * sRGBSkyCol;
        #endif
    #endif

    // Do a simple void gradient calculation
    return currSkyCol * saturate(nEyePlayerPos.y + eyeBrightFact * 3.0 - 1.0);
}

// Sky reflection
vec3 getSkyReflection(in vec3 feetPlayerPos, in vec3 reflectPlayerDir){
    // If player is in lava, return fog color
    if(isEyeInWater == 2) return fogColor;

    // Rotate normalized player position to shadow space
    vec3 skyPos = mat3(shadowModelView) * reflectPlayerDir;

    #if WORLD_LIGHT == 1 && WORLD_DAYCYCLE == 1
        // Flip if the sun has gone below the horizon
        if(dayCycle < 1) skyPos.xz = -skyPos.xz;
    #endif

    vec3 finalCol = getSkyHalf(reflectPlayerDir, skyPos, getSkyBasic(reflectPlayerDir.y, skyPos.z));

    #if CLOUD_TYPE != 0 && WORLD_CLOUDS == 1 && WORLD_LIGHT == 1
        // Get voxelized clouds
        if(eyeBrightFact > 0.00390625) finalCol = getVoxelClouds(finalCol, cloudStartPos + feetPlayerPos, reflectPlayerDir, cloudDistantFar);
    #endif

    // Do a simple void gradient calculation when underwater
    if(isEyeInWater == 1) return finalCol * max(0.0, reflectPlayerDir.y + eyeBrightFact - 1.0);

    #if WORLD_LIGHT == 1
        // Fake VL reflection
        const float fakeVLBrightness = VOLUMETRIC_LIGHTING_STRENGTH * 0.5;
        float VLBrightness = fakeVLBrightness * shdFade;

        if(reflectPlayerDir.y > 0){
            float heightFade = squared(squared(squared(1.0 - squared(reflectPlayerDir.y))));

            #if WORLD_WEATHER == 1
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

    #if WORLD_LIGHT == 1
        #if WORLD_CELESTIAL == 1 && SUN_MOON_TYPE != 2
            // If current world uses shader sun and moon but not vanilla sun and moon
            #if SUN_MOON_TYPE == 1
                float sunMoonShape = getSunMoonShape(skyPos.z) * sunMoonIntensitySqrd;
            #else
                float sunMoonShape = getSunMoonShape(skyPos.xy) * sunMoonIntensitySqrd;
            #endif

            #if WORLD_WEATHER == 1
                #if WORLD_DAYCYCLE == 0
                    currSkyCol += sRGBLightCol * (sunMoonShape - rainStrength * sunMoonShape);
                #else
                    currSkyCol += (skyPos.z > 0 ? sRGBSunCol : sRGBMoonCol) * (sunMoonShape - rainStrength * sunMoonShape);
                #endif
            #else
                #if WORLD_DAYCYCLE == 0
                    currSkyCol += sRGBLightCol * sunMoonShape;
                #else
                    currSkyCol += (skyPos.z > 0 ? sRGBSunCol : sRGBMoonCol) * sunMoonShape;
                #endif
            #endif
        #elif WORLD_CELESTIAL == 2
            float blackHole = sqrt(1.0 - skyPos.z * skyPos.z) - WORLD_CELESTIAL_SIZE;

            // If black hole return nothing
            if(blackHole <= 0) return vec3(0);
            blackHole = 1.0 / max(1.0, blackHole * 256.0);

            // Distortion application
            const float rotationFactor = TAU * 16.0;
            skyPos.xy = rot2D(blackHole * rotationFactor) * skyPos.xy;

            float rings = textureLod(noisetex, vec2(skyPos.x * blackHole, fragmentFrameTime * 0.0009765625), 0).x;

            currSkyCol += ((rings * blackHole * 0.9 + blackHole * 0.1) * sunMoonIntensitySqrd) * lightCol;
        #endif
    #endif

    // Combine sky box color and sky half color
    currSkyCol = getSkyHalf(nEyePlayerPos, skyPos, currSkyCol);

    // Do a simple void gradient calculation when underwater
    if(isEyeInWater == 1) return currSkyCol * saturate(nEyePlayerPos.y * 1.66666667 - 0.16666667);
    return currSkyCol * saturate(nEyePlayerPos.y + eyeBrightFact * 3.0 - 1.0);
}