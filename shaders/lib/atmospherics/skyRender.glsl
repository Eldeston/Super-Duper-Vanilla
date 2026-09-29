#if WORLD_ID == 1
	#ifndef END_FLASH_UNIFORM_DECLARED
		#define END_FLASH_UNIFORM_DECLARED
		uniform float endFlashIntensity;
		uniform vec3 endFlashPosition;
	#endif
#endif

#ifdef WORLD_AETHER
#endif

#include "/lib/atmospherics/milkyWay.glsl"

float getSunMoonDist(in vec2 coord, in float halfSize){
    float r = SUN_MOON_ROUNDNESS * halfSize;
    vec2 q = abs(coord) - vec2(halfSize - r);
    return min(max(q.x, q.y), 0.0) + length(max(q, vec2(0.0))) - r + halfSize;
}

float getSunMoonDist(in vec2 coord){
    return getSunMoonDist(coord, WORLD_SUN_MOON_SIZE);
}

// Round sun and moon
float getSunMoonShape(in float skyPosZ){
    return min(1.0, exp2((WORLD_SUN_MOON_SIZE - sqrt(1.0 - skyPosZ * skyPosZ)) * 256.0));
}

// Shape-adjusted sun and moon
float getSunMoonShape(in vec2 skyPos){
    return min(1.0, exp2((WORLD_SUN_MOON_SIZE - getSunMoonDist(skyPos, WORLD_SUN_MOON_SIZE)) * 256.0));
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
            cloudHeightFade -= weatherFade * 0.2;
            cloudHeightFade *= 6.0 - weatherFade * 5.0;
        #endif

        if(cloudHeightFade <= 0) return currSkyCol;
        if(cloudHeightFade > 1) cloudHeightFade = 1.0;

        vec2 planeUv = nEyePlayerPos.xz * (6.0 / nEyePlayerPos.y);
        vec2 planePos = vec2(cameraPosition.x + fragmentFrameTime, cameraPosition.z);
        vec2 cloudData = cloudParallaxDynamic(planeUv, planePos);

        #ifdef DOUBLE_LAYERED_CLOUDS
            vec2 cirrusUv = nEyePlayerPos.xz * ((6.0 + (SECOND_CLOUD_HEIGHT / 195.0) * 6.0) / nEyePlayerPos.y);
            vec2 cirrusStart = vec2(cirrusUv.x * 0.32 + cirrusUv.y * 0.128, cirrusUv.y * 1.6);
            vec2 cirrusCam = vec2(planePos.x * 0.32 + planePos.y * 0.128, planePos.y * 1.6);
            cloudData = max(cloudParallaxDynamic(cirrusStart, cirrusCam).yx * 0.20, cloudData);
        #endif

        #ifdef DYNAMIC_CLOUDS
            float fadeTime = saturate(sin(fragmentFrameTime * FADE_SPEED) * 0.8 + 0.5);

            float clouds = mix(mix(cloudData.x, cloudData.y, fadeTime), max(cloudData.x, cloudData.y), weatherFade);
        #else
            float clouds = mix(cloudData.x, max(cloudData.x, cloudData.y), weatherFade);
        #endif

        clouds *= cloudHeightFade * cloudStepSize;

        #ifndef FORCE_DISABLE_WEATHER
            #ifdef FORCE_DISABLE_DAY_CYCLE
                vec3 cloudLight = lightCol * (1.0 - weatherFade);
            #else
                vec3 cloudLight = mix(moonCol, sunCol, dayCycleAdjust) * (1.0 - weatherFade);
            #endif
            currSkyCol += cloudLight * clouds;
            currSkyCol -= currSkyCol * (clouds * weatherFade * 0.65);
        #else
            #ifdef FORCE_DISABLE_DAY_CYCLE
                currSkyCol += lightCol * clouds;
            #else
                currSkyCol += mix(moonCol, sunCol, dayCycleAdjust) * clouds;
            #endif
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
        #ifndef FORCE_DISABLE_WEATHER
            float celestialFade = 1.0 - weatherFade;
        #else
            const float celestialFade = 1.0;
        #endif
        #ifdef FORCE_DISABLE_DAY_CYCLE
            if(skyPosZ > 0) currSkyCol += lightCol * (pow(skyPosZ * skyPosZ, abs(nEyePlayerPosY) + 1.0) * celestialFade);
        #else
            float lightDiffuse = pow(skyPosZ * skyPosZ, abs(nEyePlayerPosY) + 1.0) * celestialFade;
            float diffuseCycleAdjust = dayCycleAdjust * lightDiffuse;
            currSkyCol += skyPosZ > 0 ? sunCol * diffuseCycleAdjust : moonCol * (lightDiffuse - diffuseCycleAdjust);
        #endif
    #endif

    currSkyCol += lightningFlash;

    #if WORLD_ID == 1
        currSkyCol += toLinear(vec3(0.18, 0.10, 0.26)) * (endFlashIntensity * 0.4);
    #endif

    return currSkyCol;
}

// Sky half render
vec3 getSkyHalf(in vec3 nEyePlayerPos, in vec3 skyPos, in vec3 currSkyCol){
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

    #ifdef WORLD_STARS
        // Procedural Minecraft-style square star field
        vec3 stars = getProceduralSquareStars(skyPos, fragmentFrameTime) * WORLD_STARS;

        #ifdef FORCE_DISABLE_WEATHER
            currSkyCol += stars;
        #else
            if(weatherFade < 1.0) currSkyCol += (1.0 - weatherFade) * stars;
        #endif
    #endif

    #if defined WORLD_STARS && defined WORLD_MILKY_WAY && defined MILKY_WAY
        // Procedural Minecraft-style Milky Way (appears gradually later in the night only when stars are visible, not during rain)
        float mwHorizonFade = saturate(nEyePlayerPos.y * 6.0);
        vec3 milkyWay = getProceduralMilkyWay(skyPos, fragmentFrameTime) * (mwHorizonFade * WORLD_MILKY_WAY * MILKY_WAY_BRIGHTNESS);

        #ifdef FORCE_DISABLE_WEATHER
            currSkyCol += milkyWay;
        #else
            if(weatherFade < 1.0) currSkyCol += (1.0 - weatherFade) * milkyWay;
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
                heightFade += (1.0 - heightFade) * weatherFade * 0.5;
            #endif

            VLBrightness *= heightFade;
        }
        
        finalCol += lightCol * VLBrightness;
    #endif

    return finalCol * saturate(reflectPlayerDir.y + eyeBrightFact * 3.0 - 1.0);
}

#ifndef COMPOSITE0
// Full sky render
vec3 getFullSkyRender(in vec3 nEyePlayerPos, in vec3 skyPos, in vec3 currSkyCol){
    // If player is in lava, return fog color
    if(isEyeInWater == 2) return fogColor;

    #ifdef WORLD_LIGHT
        #if WORLD_SUN_MOON == 1
            #ifndef FORCE_DISABLE_WEATHER
                if(weatherFade < 1.0 && abs(skyPos.z) > 0.7){
                    float sunMoonShape = getSunMoonShape(skyPos.xy / abs(skyPos.z)) * sunMoonIntensitySqrd;
                    #ifdef FORCE_DISABLE_DAY_CYCLE
                        currSkyCol += sRGBLightCol * (sunMoonShape * (1.0 - weatherFade));
                    #else
                        currSkyCol += (skyPos.z > 0 ? sRGBSunCol : sRGBMoonCol) * (sunMoonShape * (1.0 - weatherFade));
                    #endif
                }
            #else
                if(abs(skyPos.z) > 0.7){
                    float sunMoonShape = getSunMoonShape(skyPos.xy / abs(skyPos.z)) * sunMoonIntensitySqrd;
                    #ifdef FORCE_DISABLE_DAY_CYCLE
                        currSkyCol += sRGBLightCol * sunMoonShape;
                    #else
                        currSkyCol += (skyPos.z > 0 ? sRGBSunCol : sRGBMoonCol) * sunMoonShape;
                    #endif
                }
            #endif
        #elif WORLD_SUN_MOON == 2
            // If current world uses shader black hole
            if(skyPos.z > 0.0){
                const float blackHoleSize = 1024.0 - WORLD_SUN_MOON_SIZE * 64.0;
                const float z0 = blackHoleSize / 1024.0;
                const float bhHalfSize = sqrt(1.0 - z0 * z0) / z0;

                vec2 projPos = skyPos.xy / skyPos.z;
                float dist = getSunMoonDist(projPos, bhHalfSize);
                float shapeZ = inversesqrt(dist * dist + 1.0);
                float blackHole = blackHoleSize - shapeZ * 1024.0;

                // If black hole return nothing
                if(blackHole <= 0.0) return vec3(0.0);
                blackHole = max(0.0, 1.0 / max(1.0, blackHole) - (1.0 / blackHoleSize));

                // Distortion application (spiral wrapping around the black hole)
                const float rotationFactor = TAU * 16.0;
                skyPos.xy = rot2D(blackHole * rotationFactor) * skyPos.xy;

                float rings = textureLod(noisetex, vec2(skyPos.x * blackHole, fragmentFrameTime * 0.0009765625), 0).x;

                currSkyCol += (((rings * blackHole * 0.9 + blackHole * 0.1) * (sunMoonIntensitySqrd * 0.35)) * lightCol);
            }
        #endif

        #if WORLD_ID == 1
            if(endFlashIntensity > 0.001){
                vec3 flashDir = fastNormalize(mat3(gbufferModelViewInverse) * endFlashPosition);
                float flashDot = dot(nEyePlayerPos, flashDir);
                if(flashDot > 0.0){
                    float d2 = flashDot * flashDot; float d4 = d2 * d2; float d8 = d4 * d4;
                    float flashGlow = d8 * d8; float d32 = flashGlow * flashGlow; float d64 = d32 * d32;
                    float flashCore = d64 * d64;
                    float flashBurst = (flashCore * 6.0 + flashGlow * 1.5 + d2 * 0.3) * endFlashIntensity;
                    currSkyCol += toLinear(vec3(0.85, 0.75, 1.0)) * flashBurst;
                }
            }
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
#endif // !COMPOSITE0