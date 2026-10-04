#if WORLD_ID == 1
	#ifndef END_FLASH_UNIFORM_DECLARED
		#define END_FLASH_UNIFORM_DECLARED
		uniform float endFlashIntensity;
		uniform vec3 endFlashPosition;
	#endif
#endif

#include "/lib/atmospherics/celestialRender.glsl"
#include "/lib/atmospherics/milkyWay.glsl"
#include "/lib/atmospherics/meteorShowers.glsl"
#include "/lib/atmospherics/aurora.glsl"
#include "/lib/atmospherics/rainbow.glsl"
#include "/lib/atmospherics/cloudOcclusion.glsl"
#include "/lib/atmospherics/lightning.glsl"

#if WORLD_ID == 0 && !defined FORCE_DISABLE_WEATHER
    #ifndef THUNDER_STRENGTH_DECLARED
        #define THUNDER_STRENGTH_DECLARED
        uniform float thunderStrength;
    #endif
    #define getEffectiveWeatherFade() clamp(max(weatherFade, thunderStrength), 0.0, 1.0)
#else
    #define getEffectiveWeatherFade() weatherFade
#endif

#if CLOUD_TYPE != 0 && !defined FORCE_DISABLE_CLOUDS && defined WORLD_LIGHT
    // Depth size / cloud steps
    const uint skyBoxCloudSteps = uint(SKYBOX_CLOUD_STEPS);
    const float cloudStepSize = 1.0 / skyBoxCloudSteps, depthSize = SKYBOX_CLOUD_DEPTH * cloudStepSize;

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
            float cloudWeatherFade = getEffectiveWeatherFade();
            #ifdef DYNAMIC_WEATHER
                if(cloudWeatherFade <= 0.001) return currSkyCol;
            #endif
        #endif

        float cloudHeightFade = nEyePlayerPos.y - 0.1;

        #ifdef FORCE_DISABLE_WEATHER
            cloudHeightFade *= 6.0;
        #else
            cloudHeightFade -= cloudWeatherFade * 0.2;
            cloudHeightFade *= 6.0 - cloudWeatherFade * 5.0;
        #endif

        if(cloudHeightFade <= 0) return currSkyCol;
        if(cloudHeightFade > 1) cloudHeightFade = 1.0;

        float invEyeY = 1.0 / nEyePlayerPos.y;
        vec2 planeUv = nEyePlayerPos.xz * (6.0 * invEyeY);
        vec2 planePos = vec2(cameraPosition.x + fragmentFrameTime, cameraPosition.z);
        vec2 cloudData = cloudParallaxDynamic(planeUv, planePos);

        #ifdef DOUBLE_LAYERED_CLOUDS
            #ifndef FORCE_DISABLE_WEATHER
                if(cloudWeatherFade < 0.65 && cloudWeatherFade > 0.001){
                    vec2 cirrusUv = nEyePlayerPos.xz * ((6.0 + (SECOND_CLOUD_HEIGHT / 195.0) * 6.0) * invEyeY);
                    vec2 cirrusStart = vec2(cirrusUv.x * 0.32 + cirrusUv.y * 0.128, cirrusUv.y * 1.6);
                    vec2 cirrusCam = vec2(planePos.x * 0.32 + planePos.y * 0.128, planePos.y * 1.6);
                    float cirrusFactor = smoothstep(0.0, 0.20, cloudWeatherFade) * (1.0 - smoothstep(0.30, 0.65, cloudWeatherFade));
                    cloudData = max(cloudParallaxDynamic(cirrusStart, cirrusCam).yx * (0.20 * cirrusFactor), cloudData);
                }
            #else
                vec2 cirrusUv = nEyePlayerPos.xz * ((6.0 + (SECOND_CLOUD_HEIGHT / 195.0) * 6.0) * invEyeY);
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
                float cloudPresence = smoothstep(0.0, 0.40, cloudWeatherFade);
                baseClouds *= cloudPresence;
                // Mix in expanded coverage from both channels
                float expandedClouds = mix(baseClouds, max(cloudData.x, cloudData.y) * cloudPresence, cloudWeatherFade);
                // Overcast scales the optical density of the first layer of clouds
                float firstLayerDensity = mix(0.75, 2.0, smoothstep(0.10, 0.85, cloudWeatherFade));
                // As overcast approaches 1.0, an overcast cloud deck fills the sky
                float overcastDeck = saturate((cloudWeatherFade - 0.70) * 4.0);
                float clouds = mix(expandedClouds, max(expandedClouds, float(skyBoxCloudSteps) * 0.70), overcastDeck);
                clouds *= firstLayerDensity;
            #else
                float clouds = mix(baseClouds, max(cloudData.x, cloudData.y), cloudWeatherFade);
            #endif
        #else
            float clouds = baseClouds;
        #endif

        clouds *= cloudHeightFade * cloudStepSize;

        #ifndef FORCE_DISABLE_WEATHER
            #ifdef FORCE_DISABLE_DAY_CYCLE
                vec3 cloudLight = lightCol * (1.0 - cloudWeatherFade);
            #else
                vec3 cloudLight = mix(moonCol, sunCol, dayCycleAdjust) * (1.0 - cloudWeatherFade);
            #endif
            #ifdef STORY_MODE_CLOUDS
                vec3 cloudSkyLight = mix(skyCol, skyCol * 0.85, cloudWeatherFade);
            #else
                vec3 cloudSkyLight = mix(skyCol, skyCol * 0.35, cloudWeatherFade);
            #endif
        #else
            #ifdef FORCE_DISABLE_DAY_CYCLE
                vec3 cloudLight = lightCol;
            #else
                vec3 cloudLight = mix(moonCol, sunCol, dayCycleAdjust);
            #endif
            vec3 cloudSkyLight = skyCol;
        #endif

        float cloudAlpha = saturate(clouds * 1.6);
        #if WORLD_ID == 0 && defined CLOUD_LIGHTNING_GLOW && !defined EPILEPSY_SAFETY
            cloudLight += getCloudInternalFlashGlow(nEyePlayerPos, cloudAlpha);
        #endif
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
            float weatherSkyGrad = 1.0 - getEffectiveWeatherFade();
        #else
            const float weatherSkyGrad = 1.0;
        #endif
        float moonSkyGrad = mix(1.0, mix(0.65, 1.0, smoothstep(0.0, 1.0, moonAlignment)), nightFactor * weatherSkyGrad);
        baseSky *= moonSkyGrad;
    #endif
    // Apply ambient lighting with sky col (not realistic I know)
    vec3 currSkyCol = baseSky + toLinear(AMBIENT_LIGHTING + nightVision * 0.5);

    #ifdef WORLD_SKY_GROUND
        if(nEyePlayerPosY < 0 && isEyeInWater == 0) currSkyCol *= exp2(-(nEyePlayerPosY * nEyePlayerPosY * 8.0) / max(baseSky * baseSky, vec3(0.125)));
    #endif

    #if defined WORLD_LIGHT && WORLD_SUN_MOON == 1
        #ifndef FORCE_DISABLE_WEATHER
            float celestialFade = 1.0 - getEffectiveWeatherFade();
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

    #ifndef EPILEPSY_SAFETY
        currSkyCol += toLinear(mix(vec3(1.0), LIGHTNING_COLOR, 0.15)) * getLightningFlashIntensity();
    #endif

    #if WORLD_ID == 1 && !defined EPILEPSY_SAFETY
        float flashAmbWeight = smoothstep(0.18, 0.50, endFlashIntensity);
        currSkyCol += toLinear(vec3(0.18, 0.10, 0.26)) * (endFlashIntensity * flashAmbWeight * 0.4);
    #endif
    return currSkyCol;
}

#if defined WORLD_AETHER && defined WORLD_LIGHT
vec3 getAetherRender(in vec3 nEyePlayerPos, in vec3 skyPos){
    float horizonFade = exp2(-abs(nEyePlayerPos.y) * 8.0);
    if(horizonFade <= 0.002) return vec3(0.0);

    // Continuous smooth animation speed (eliminates 8 FPS quantization stutter)
    float aetherTime = fragmentFrameTime * 0.03125;

    // Smooth continuous floating-point UV coordinates wrapped by hardware
    vec2 uvBase = skyPos.xy;
    vec2 uv0 = 1.0 - uvBase - aetherTime;
    vec2 uv1 = vec2(uv0.x, uvBase.y - aetherTime);
    vec2 uv2 = vec2(uvBase.x - aetherTime, uv0.y);

    // Hardware-accelerated bilinear filtering eliminates all nearest-neighbor texel jitter
    vec3 aetherNoise = vec3(
        textureLod(noisetex, uv0, 0).z,
        textureLod(noisetex, uv1, 0).z,
        textureLod(noisetex, uv2, 0).z
    );

    return horizonFade * cubed(aetherNoise * lightCol + sumOf(aetherNoise) * 0.66666666) * lightCol;
}
#endif

// Sky half render
vec3 getSkyHalf(in vec3 nEyePlayerPos, in vec3 skyPos, in vec3 currSkyCol){
    #if defined WORLD_AETHER && defined WORLD_LIGHT
        currSkyCol += getAetherRender(nEyePlayerPos, skyPos);
    #endif

    #ifndef FORCE_DISABLE_WEATHER
        float skyClearFade = 1.0 - getEffectiveWeatherFade();
    #else
        const float skyClearFade = 1.0;
    #endif

    #ifdef WORLD_STARS
        #ifndef MOON_PHASE_FACTOR
            #define MOON_PHASE_FACTOR 1.0
        #endif
        // Moonlight washes out faint stars and the Milky Way at night
        float starMoonFade = mix(1.0, 0.45, MOON_PHASE_FACTOR);
        vec3 stars = getProceduralSquareStars(skyPos, fragmentFrameTime) * (WORLD_STARS * starMoonFade);
        if(skyClearFade > 0.0) currSkyCol += skyClearFade * stars;
    #endif

    #ifdef MILKY_WAY
    #if defined WORLD_STARS && defined WORLD_MILKY_WAY
        // Procedural Minecraft-style Milky Way (appears smoothly alongside stars during dusk, not during rain)
        float mwHorizonFade = saturate(nEyePlayerPos.y * 6.0);
        float mwMoonFade = mix(1.0, 0.15, MOON_PHASE_FACTOR);
        vec3 milkyWay = getProceduralMilkyWay(skyPos, fragmentFrameTime) * (mwHorizonFade * WORLD_MILKY_WAY * MILKY_WAY_BRIGHTNESS * mwMoonFade);
        if(skyClearFade > 0.0) currSkyCol += skyClearFade * milkyWay;
    #endif
    #endif

    #ifdef METEORS
    #if defined WORLD_STARS && defined WORLD_METEORS
        // Procedural meteor showers (variable strength, crisp tails fading out, blue-ish aesthetic)
        float meteorHorizonFade = saturate(nEyePlayerPos.y * 6.0);
        float meteorMoonFade = mix(1.0, 0.35, MOON_PHASE_FACTOR);
        vec3 meteors = getProceduralMeteorShowers(nEyePlayerPos, skyPos, fragmentFrameTime) * (meteorHorizonFade * WORLD_METEORS * METEOR_BRIGHTNESS * meteorMoonFade);
        if(skyClearFade > 0.0) currSkyCol += skyClearFade * meteors;
    #endif
    #endif

    #ifdef AURORA
    #if defined WORLD_LIGHT && defined WORLD_AURORA
        float auroraCold = isColdBiome;
        if(auroraCold > 0.001 && nEyePlayerPos.y > 0.035 && skyClearFade > 0.001){
            float auroraMoonFade = mix(1.0, 0.70, MOON_PHASE_FACTOR);
            vec3 aurora = getVolumetricAurora(nEyePlayerPos, fragmentFrameTime) * (WORLD_AURORA * AURORA_BRIGHTNESS * auroraCold * skyClearFade * auroraMoonFade);
            currSkyCol += skyClearFade * aurora;
        }
    #endif
    #endif

    return currSkyCol;
}

// Fog color render
vec3 getSkyFogRender(in vec3 nEyePlayerPos, in vec3 skyPos, in vec3 currSkyCol){
    // If player is in water, return nothing if it's not the sky
    if(isEyeInWater == 1) return vec3(0);
    // If player is in lava, return fog color
    if(isEyeInWater == 2) return fogColor;

    #if defined WORLD_AETHER && defined WORLD_LIGHT
        currSkyCol += getAetherRender(nEyePlayerPos, skyPos);
    #endif

    #ifndef WORLD_CUSTOM_SKYLIGHT
        float skyExposure = smoothstep(0.08, 0.40, eyeBrightFact);
    #else
        const float skyExposure = 1.0;
    #endif

    // Void gradient calculation, modulated by skylight so caves and underground stay dark
    float voidGrad = saturate(nEyePlayerPos.y * 2.0 + 1.0);
    vec3 outdoorFog = currSkyCol * voidGrad;
    vec3 caveFog = vec3(toLinear(AMBIENT_LIGHTING + nightVision * 0.5));

    return mix(caveFog, outdoorFog, skyExposure);
}

vec3 getSkyFogRender(in vec3 nEyePlayerPos){
    vec3 skyPos = mat3(shadowModelView) * nEyePlayerPos;
    #if defined WORLD_LIGHT && !defined FORCE_DISABLE_DAY_CYCLE
        if(dayCycle < 1) skyPos.xz = -skyPos.xz;
    #endif
    return getSkyFogRender(nEyePlayerPos, skyPos, getSkyBasic(nEyePlayerPos.y, skyPos.z));
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

    // Skybox clouds should render in reflections when volumetrics are on
    #if CLOUD_TYPE != 0 && !defined FORCE_DISABLE_CLOUDS && defined WORLD_LIGHT
        finalCol = getSkyClouds(reflectPlayerDir, finalCol);
    #endif

    #ifdef RAINBOW
        #if WORLD_ID == 0 && defined WORLD_LIGHT
            #ifndef FORCE_DISABLE_WEATHER
                finalCol += getRainbowRender(reflectPlayerDir, skyPos);
            #endif
        #endif
    #endif

    // Do a simple void gradient calculation when underwater
    if(isEyeInWater == 1) return finalCol * max(0.0, reflectPlayerDir.y + eyeBrightFact - 1.0);

    #ifdef WORLD_LIGHT
        // Fake VL reflection
        const float fakeVLBrightness = VOLUMETRIC_LIGHTING_STRENGTH * 0.5;
        float VLBrightness = fakeVLBrightness * shdFade;
        #if WORLD_ID == 1
            #ifdef EPILEPSY_SAFETY
                float flashReflWeight = 0.0;
            #else
                float flashReflWeight = smoothstep(0.18, 0.50, endFlashIntensity) * endFlashIntensity;
            #endif
            VLBrightness *= flashReflWeight;
        #endif

        if(reflectPlayerDir.y > 0){
            float heightFade = squared(squared(squared(1.0 - squared(reflectPlayerDir.y))));

            #ifndef FORCE_DISABLE_WEATHER
                heightFade += (1.0 - heightFade) * getEffectiveWeatherFade() * 0.5;
            #endif

            VLBrightness *= heightFade;
        }
        
        #ifndef FORCE_DISABLE_WEATHER
            finalCol += mix(lightCol, skyCol, getEffectiveWeatherFade()) * VLBrightness;
        #else
            finalCol += lightCol * VLBrightness;
        #endif
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
        float flashWeight = smoothstep(0.18, 0.50, endFlashIntensity);
        float flashBurst = (flashCore * 6.0 + flashGlow * 1.5 + flashAura * 0.3) * (endFlashIntensity * flashWeight);
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
                float sunMoonFade = getEffectiveWeatherFade();
                bool renderCelestial = sunMoonFade < 1.0 && abs(skyPos.z) > 0.7;
                float celestialVis = 1.0 - sunMoonFade;
            #else
                bool renderCelestial = abs(skyPos.z) > 0.7;
                const float celestialVis = 1.0;
            #endif
            if(renderCelestial){
                vec3 lightDir = vec3(shadowModelView[0].z, shadowModelView[1].z, shadowModelView[2].z);
                float cloudOcc = getCloudCelestialOcclusion(lightDir, cameraPosition, fragmentFrameTime);
                #ifdef FORCE_DISABLE_DAY_CYCLE
                    float sunMoonShape = getSunMoonShape(skyPos.xy / abs(skyPos.z)) * sunMoonIntensitySqrd;
                    currSkyCol += sRGBLightCol * (sunMoonShape * (celestialVis * cloudOcc));
                #else
                    float cFade = 1.0 - celestialVis;
                    if(skyPos.z > 0.0){
                        float effSun = max(sunPower / max(0.20, celestialVis), 0.60);
                        currSkyCol += getSunRender(skyPos.xy / abs(skyPos.z), sRGBSunCol * (effSun * cloudOcc), cFade);
                    } else {
                        float effMoon = max(moonPower / max(0.20, celestialVis), 0.60);
                        currSkyCol += getMoonRender(skyPos.xy / abs(skyPos.z), sRGBMoonCol * (effMoon * cloudOcc), cFade);
                    }
                #endif
            }
        #elif WORLD_SUN_MOON == 2
            // If current world uses shader black hole
            if(skyPos.z > 0.0){
                bool isHoleCore = false;
                vec3 bhCol = getBlackHoleRender(skyPos, lightCol, sunMoonIntensitySqrd, fragmentFrameTime, isHoleCore);
                if(isHoleCore) return vec3(0.0);
                currSkyCol += bhCol;
            }
        #endif

        #if WORLD_ID == 1 && !defined EPILEPSY_SAFETY
            if(endFlashIntensity > 0.18){
                currSkyCol += getEndFlash(nEyePlayerPos);
            }
        #endif
    #endif

    #if WORLD_ID == 0 && defined WORLD_LIGHT && !defined EPILEPSY_SAFETY
        #ifdef CLOUD_LIGHTNING
            currSkyCol += getCloudLightningRender(nEyePlayerPos);
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
