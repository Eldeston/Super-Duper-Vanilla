#if WORLD_ID == 1
	#ifndef END_FLASH_UNIFORM_DECLARED
		#define END_FLASH_UNIFORM_DECLARED
		uniform float endFlashIntensity;
		uniform vec3 endFlashPosition;
	#endif
#endif

#ifdef WORLD_AETHER
#endif

#include "/lib/atmospherics/celestialRender.glsl"
#include "/lib/atmospherics/milkyWay.glsl"
#include "/lib/atmospherics/aurora.glsl"
#include "/lib/atmospherics/rainbow.glsl"

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
        #ifndef FORCE_DISABLE_WEATHER
            #ifdef DYNAMIC_WEATHER
                if(weatherFade <= 0.001) return currSkyCol;
            #endif
        #endif

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
            #ifndef FORCE_DISABLE_WEATHER
                if(weatherFade < 1.0 && weatherFade > 0.001){
                    vec2 cirrusUv = nEyePlayerPos.xz * ((6.0 + (SECOND_CLOUD_HEIGHT / 195.0) * 6.0) / nEyePlayerPos.y);
                    vec2 cirrusStart = vec2(cirrusUv.x * 0.32 + cirrusUv.y * 0.128, cirrusUv.y * 1.6);
                    vec2 cirrusCam = vec2(planePos.x * 0.32 + planePos.y * 0.128, planePos.y * 1.6);
                    float cirrusFactor = smoothstep(0.0, 0.25, weatherFade) * (1.0 - weatherFade);
                    cloudData = max(cloudParallaxDynamic(cirrusStart, cirrusCam).yx * (0.20 * cirrusFactor), cloudData);
                }
            #else
                vec2 cirrusUv = nEyePlayerPos.xz * ((6.0 + (SECOND_CLOUD_HEIGHT / 195.0) * 6.0) / nEyePlayerPos.y);
                vec2 cirrusStart = vec2(cirrusUv.x * 0.32 + cirrusUv.y * 0.128, cirrusUv.y * 1.6);
                vec2 cirrusCam = vec2(planePos.x * 0.32 + planePos.y * 0.128, planePos.y * 1.6);
                cloudData = max(cloudParallaxDynamic(cirrusStart, cirrusCam).yx * 0.20, cloudData);
            #endif
        #endif

        #ifdef DYNAMIC_CLOUDS
            float fadeTime = saturate(sin(fragmentFrameTime * FADE_SPEED) * 0.8 + 0.5);

            float baseClouds = mix(cloudData.x, cloudData.y, fadeTime);
        #else
            float baseClouds = cloudData.x;
        #endif

        #ifndef FORCE_DISABLE_WEATHER
            #ifdef DYNAMIC_WEATHER
                // Scale clouds smoothly as overcast rises from clear to partly cloudy
                float cloudPresence = smoothstep(0.0, 0.40, weatherFade);
                baseClouds *= cloudPresence;

                // Mix in expanded coverage from both channels
                float expandedClouds = mix(baseClouds, max(cloudData.x, cloudData.y) * cloudPresence, weatherFade);

                // As overcast approaches 1.0, an overcast cloud deck fills the sky
                float overcastDeck = saturate((weatherFade - 0.70) * 4.0);
                float clouds = mix(expandedClouds, max(expandedClouds, float(skyBoxCloudSteps) * 0.70), overcastDeck);
            #else
                float clouds = mix(baseClouds, max(cloudData.x, cloudData.y), weatherFade);
            #endif
        #else
            float clouds = baseClouds;
        #endif

        clouds *= cloudHeightFade * cloudStepSize;

        #ifndef FORCE_DISABLE_WEATHER
            #ifdef FORCE_DISABLE_DAY_CYCLE
                vec3 cloudLight = lightCol * (1.0 - weatherFade);
            #else
                vec3 cloudLight = mix(moonCol, sunCol, dayCycleAdjust) * (1.0 - weatherFade);
            #endif
            vec3 cloudSkyLight = mix(skyCol, skyCol * 0.35, weatherFade);
        #else
            #ifdef FORCE_DISABLE_DAY_CYCLE
                vec3 cloudLight = lightCol;
            #else
                vec3 cloudLight = mix(moonCol, sunCol, dayCycleAdjust);
            #endif
            vec3 cloudSkyLight = skyCol;
        #endif

        float cloudAlpha = saturate(clouds * 1.6);
        vec3 celestialExcess = max(vec3(0.0), currSkyCol - cloudSkyLight);
        vec3 occludedSky = min(currSkyCol, cloudSkyLight) + celestialExcess * exp2(-cloudAlpha * 8.0);
        return mix(occludedSky, cloudSkyLight + cloudLight, cloudAlpha);
    }

#endif

vec3 getSkyBasic(in float nEyePlayerPosY, in float skyPosZ){
    vec3 baseSky = skyCol;

    #if defined WORLD_LIGHT && WORLD_SUN_MOON == 1 && !defined FORCE_DISABLE_DAY_CYCLE
        // Night sky gradient: smoothly darker away from the moon
        float moonAlignment = saturate(-skyPosZ * 0.5 + 0.5);
        float nightFactor = saturate(1.0 - dayCycle);
        #ifndef FORCE_DISABLE_WEATHER
            float weatherSkyGrad = 1.0 - weatherFade;
        #else
            const float weatherSkyGrad = 1.0;
        #endif
        float moonSkyGrad = mix(1.0, mix(0.65, 1.0, smoothstep(0.0, 1.0, moonAlignment)), nightFactor * weatherSkyGrad);
        baseSky *= moonSkyGrad;
    #endif

    // Apply ambient lighting with sky col (not realistic I know)
    vec3 currSkyCol = baseSky + toLinear(AMBIENT_LIGHTING + nightVision * 0.5);

    #ifdef WORLD_SKY_GROUND
        // currSkyCol.rg *= smoothen(saturate(1.0 + nEyePlayerPosY * 4.0));
        // if(nEyePlayerPosY < 0) currSkyCol *= smoothen(max(1.0 + nEyePlayerPosY / max(skyCol, 0.25), vec3(0.25)));
        if(nEyePlayerPosY < 0 && isEyeInWater == 0) currSkyCol *= exp2(-(nEyePlayerPosY * nEyePlayerPosY * 8.0) / max(baseSky * baseSky, vec3(0.125)));
    #endif

    #if defined WORLD_LIGHT && WORLD_SUN_MOON == 1
        #ifndef FORCE_DISABLE_WEATHER
            float celestialFade = 1.0 - smoothstep(0.70, 0.95, weatherFade);
        #else
            const float celestialFade = 1.0;
        #endif
        #ifdef FORCE_DISABLE_DAY_CYCLE
            if(skyPosZ > 0) currSkyCol += lightCol * (pow(skyPosZ * skyPosZ, abs(nEyePlayerPosY) + 1.0) * celestialFade);
        #else
            float lightDiffuse = pow(skyPosZ * skyPosZ, abs(nEyePlayerPosY) + 1.0) * celestialFade;
            float diffuseCycleAdjust = dayCycleAdjust * lightDiffuse;
            #ifndef MOON_PHASE_FACTOR
                #define MOON_PHASE_FACTOR 1.0
            #endif
            float moonSkyDiffuse = (lightDiffuse - diffuseCycleAdjust) * (0.25 * mix(0.05, 1.0, MOON_PHASE_FACTOR));
            currSkyCol += skyPosZ > 0 ? sunCol * diffuseCycleAdjust : moonCol * moonSkyDiffuse;
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
        #ifndef MOON_PHASE_FACTOR
            #define MOON_PHASE_FACTOR 1.0
        #endif
        // Moonlight washes out faint stars and the Milky Way at night
        float starMoonFade = mix(1.0, 0.45, MOON_PHASE_FACTOR);
        vec3 stars = getProceduralSquareStars(skyPos, fragmentFrameTime) * (WORLD_STARS * starMoonFade);

        #ifdef FORCE_DISABLE_WEATHER
            currSkyCol += stars;
        #else
            if(weatherFade < 1.0) currSkyCol += (1.0 - weatherFade) * stars;
        #endif
    #endif

    #ifdef MILKY_WAY
    #if defined WORLD_STARS && defined WORLD_MILKY_WAY
        // Procedural Minecraft-style Milky Way (appears smoothly alongside stars during dusk, not during rain)
        float mwHorizonFade = saturate(nEyePlayerPos.y * 6.0);
        float mwMoonFade = mix(1.0, 0.15, MOON_PHASE_FACTOR);
        vec3 milkyWay = getProceduralMilkyWay(skyPos, fragmentFrameTime) * (mwHorizonFade * WORLD_MILKY_WAY * MILKY_WAY_BRIGHTNESS * mwMoonFade);

        #ifdef FORCE_DISABLE_WEATHER
            currSkyCol += milkyWay;
        #else
            if(weatherFade < 1.0) currSkyCol += (1.0 - weatherFade) * milkyWay;
        #endif
    #endif
    #endif

    #ifdef AURORA
    #if defined WORLD_LIGHT && defined WORLD_AURORA
        float auroraCold = isColdBiome;
        if(auroraCold > 0.001 && nEyePlayerPos.y > 0.035){
            #ifdef FORCE_DISABLE_WEATHER
                float auroraWeather = 1.0;
            #else
                float auroraWeather = 1.0 - weatherFade;
            #endif
            if(auroraWeather > 0.001){
                float auroraMoonFade = mix(1.0, 0.70, MOON_PHASE_FACTOR);
                vec3 aurora = getVolumetricAurora(nEyePlayerPos, fragmentFrameTime) * (WORLD_AURORA * AURORA_BRIGHTNESS * auroraCold * auroraWeather * auroraMoonFade);

                #ifdef FORCE_DISABLE_WEATHER
                    currSkyCol += aurora;
                #else
                    if(weatherFade < 1.0) currSkyCol += (1.0 - weatherFade) * aurora;
                #endif
            }
        }
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
    return currSkyCol * saturate(nEyePlayerPos.y * 2.0 + eyeBrightFact * 2.0);
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
    return currSkyCol * saturate(nEyePlayerPos.y * 2.0 + eyeBrightFact * 2.0);
}

// Sky reflection
vec3 getSkyReflection(in vec3 reflectViewDir){
    // If player is in lava, return fog color
    if(isEyeInWater == 2) return fogColor;

    vec3 reflectPlayerDir = mat3(gbufferModelViewInverse) * reflectViewDir;

    // Rotate normalized player position to shadow space (or black hole matrix in the End)
    #if WORLD_ID == 1
        const mat3 blackHoleSkyMatrix = mat3(
            1.0,  0.0,         0.0,
            0.0, -0.7431448,   0.6691306,
            0.0, -0.6691306,  -0.7431448
        );
        vec3 skyPos = blackHoleSkyMatrix * reflectPlayerDir;
    #else
        vec3 skyPos = mat3(shadowModelView) * reflectPlayerDir;
    #endif

    #if defined WORLD_LIGHT && !defined FORCE_DISABLE_DAY_CYCLE
        // Flip if the sun has gone below the horizon
        if(dayCycle < 1) skyPos.xz = -skyPos.xz;
    #endif

    vec3 finalCol = getSkyHalf(reflectPlayerDir, skyPos, getSkyBasic(reflectPlayerDir.y, skyPos.z));

    #ifdef RAINBOW
        #if WORLD_ID == 0 && defined WORLD_LIGHT
            #ifndef FORCE_DISABLE_WEATHER
                finalCol += getRainbowRender(reflectPlayerDir, skyPos);
            #endif
        #endif
    #endif

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

    return finalCol * saturate(reflectPlayerDir.y * 2.0 + eyeBrightFact * 2.0);
}

#if WORLD_ID == 1
    vec3 getEndFlash(in vec3 nEyePlayerPos){
        vec3 flashDir = fastNormalize(mat3(gbufferModelViewInverse) * endFlashPosition);
        float flashDot = dot(nEyePlayerPos, flashDir);
        if(flashDot <= 0.0) return vec3(0.0);

        vec3 upRef = abs(flashDir.y) < 0.999 ? vec3(0.0, 1.0, 0.0) : vec3(0.0, 0.0, 1.0);
        vec3 tanX = fastNormalize(cross(upRef, flashDir));
        vec3 tanY = cross(flashDir, tanX);
        vec2 projPos = vec2(dot(nEyePlayerPos, tanX), dot(nEyePlayerPos, tanY)) / max(flashDot, 0.0001);

        float dist = getSunMoonDist(projPos, WORLD_SUN_MOON_SIZE);
        float boxDist = mix(max(abs(projPos.x), abs(projPos.y)), dist, SUN_MOON_ROUNDNESS);
        float shapeZ = inversesqrt(boxDist * boxDist + 1.0);

        float d2 = shapeZ * shapeZ; float d4 = d2 * d2; float d8 = d4 * d4;
        float flashGlow = d8 * d8; float d32 = flashGlow * flashGlow; float d64 = d32 * d32;
        float flashCore = d64 * d64;
        float flashAura = flashDot * flashDot;
        float flashBurst = (flashCore * 6.0 + flashGlow * 1.5 + flashAura * 0.3) * endFlashIntensity;
        return toLinear(vec3(0.85, 0.75, 1.0)) * flashBurst;
    }
#endif

#ifndef COMPOSITE0
// Full sky render
vec3 getFullSkyRender(in vec3 nEyePlayerPos, in vec3 skyPos, in vec3 currSkyCol){
    // If player is in lava, return fog color
    if(isEyeInWater == 2) return fogColor;

    #ifdef WORLD_LIGHT
        #if WORLD_SUN_MOON == 1
            #ifndef FORCE_DISABLE_WEATHER
                if(weatherFade < 0.95 && abs(skyPos.z) > 0.7){
                    #ifdef FORCE_DISABLE_DAY_CYCLE
                        float sunMoonShape = getSunMoonShape(skyPos.xy / abs(skyPos.z)) * sunMoonIntensitySqrd;
                        float celestialVis = 1.0 - smoothstep(0.70, 0.95, weatherFade);
                        currSkyCol += sRGBLightCol * (sunMoonShape * celestialVis);
                    #else
                        if(skyPos.z > 0.0){
                            currSkyCol += getSunRender(skyPos.xy / abs(skyPos.z), sRGBSunCol, weatherFade);
                        } else {
                            currSkyCol += getMoonRender(skyPos.xy / abs(skyPos.z), sRGBMoonCol, weatherFade);
                        }
                    #endif
                }
            #else
                if(abs(skyPos.z) > 0.7){
                    #ifdef FORCE_DISABLE_DAY_CYCLE
                        float sunMoonShape = getSunMoonShape(skyPos.xy / abs(skyPos.z)) * sunMoonIntensitySqrd;
                        currSkyCol += sRGBLightCol * sunMoonShape;
                    #else
                        if(skyPos.z > 0.0){
                            currSkyCol += getSunRender(skyPos.xy / abs(skyPos.z), sRGBSunCol, 0.0);
                        } else {
                            currSkyCol += getMoonRender(skyPos.xy / abs(skyPos.z), sRGBMoonCol, 0.0);
                        }
                    #endif
                }
            #endif
        #elif WORLD_SUN_MOON == 2
            // If current world uses shader black hole
            if(skyPos.z > 0.0){
                bool isHoleCore = false;
                vec3 bhCol = getBlackHoleRender(skyPos, lightCol, sunMoonIntensitySqrd, fragmentFrameTime, isHoleCore);
                if(isHoleCore) return vec3(0.0);
                currSkyCol += bhCol;
            }
        #endif

        #if WORLD_ID == 1
            if(endFlashIntensity > 0.001){
                currSkyCol += getEndFlash(nEyePlayerPos);
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
    return currSkyCol * saturate(nEyePlayerPos.y * 2.0 + eyeBrightFact * 2.0);
}
#endif // !COMPOSITE0