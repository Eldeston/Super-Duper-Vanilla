/*
================================ /// Super Duper Vanilla v1.3.8 /// ================================

    Atmospheric God Rays (Crepuscular Rays) - Hyper-Optimized Implementation
    Blazing fast screen-space volumetric light shafts with:
    - Zero-cost early outs for fragments outside the forward-scattering phase cone
    - Celestial direct visibility gating (terrain/hand occlusion & cloud overcast)
    - Closed-form affine world-space ray projection (zero matrix inversions in raymarch)
    - Single-depth-sample sky fast-path (depthtex0 without depthtex1 for sky pixels)
    - Hardware-accelerated Henyey-Greenstein phase function (inversesqrt)
    - Configurable quality profiles (Fast: 6, Balanced: 8, High: 12, Ultra: 16)
    - Optional water/translucent transmission toggle

================================ /// Super Duper Vanilla v1.3.8 /// ================================
*/

#ifndef GODRAYS_GLSL
#define GODRAYS_GLSL

#ifndef PI
    #define PI 3.14159265
#endif

// Quality profile step counts and geometric normalization factors (decay = 0.90)
#if GODRAYS_QUALITY == 0
    #define GODRAY_STEPS 6
    #define GODRAY_NORM_FACTOR 0.213423  // (1.0 - 0.90) / (1.0 - 0.90^6)
#elif GODRAYS_QUALITY == 1
    #define GODRAY_STEPS 8
    #define GODRAY_NORM_FACTOR 0.175582  // (1.0 - 0.90) / (1.0 - 0.90^8)
#elif GODRAYS_QUALITY == 2
    #define GODRAY_STEPS 12
    #define GODRAY_NORM_FACTOR 0.139360  // (1.0 - 0.90) / (1.0 - 0.90^12)
#else
    #define GODRAY_STEPS 16
    #define GODRAY_NORM_FACTOR 0.122745  // (1.0 - 0.90) / (1.0 - 0.90^16)
#endif

// Helper to fetch celestial occluder depth (incorporating DH and Voxy)
float sampleLightDepth(in vec2 coord){
    float d = textureLod(depthtex0, coord, 0).x;
    #ifdef DISTANT_HORIZONS
        d = min(d, textureLod(dhDepthTex0, coord, 0).x);
    #elif defined VOXY
        float vx = textureLod(vxDepthTexOpaque, coord, 0).x;
        if(vx > 0.0 && vx < 1.0) d = min(d, vx);
    #endif
    return d;
}

// Fast celestial direct visibility check with 1-sample open sky fast-path
float getCelestialTerrainVisibility(in vec2 lightPos){
    if(clamp(lightPos, 0.0, 1.0) != lightPos) return 0.0;

    float d0 = sampleLightDepth(lightPos);
    if(d0 >= 0.99999) return 1.0;

    const vec2 sunOffset = vec2(0.012, 0.012);
    float d1 = sampleLightDepth(lightPos + vec2(sunOffset.x, 0.0));
    float d2 = sampleLightDepth(lightPos - vec2(sunOffset.x, 0.0));
    float d3 = sampleLightDepth(lightPos + vec2(0.0, sunOffset.y));
    float d4 = sampleLightDepth(lightPos - vec2(0.0, sunOffset.y));

    float v1 = step(0.99999, d1);
    float v2 = step(0.99999, d2);
    float v3 = step(0.99999, d3);
    float v4 = step(0.99999, d4);

    return (v1 + v2 + v3 + v4) * 0.25;
}

// Checks if celestial disk is occluded by thick clouds
float getCelestialCloudVisibility(in vec3 lightDir){
    #if CLOUD_TYPE != 0 && !defined FORCE_DISABLE_CLOUDS
        #ifdef STORY_MODE_CLOUDS
            const float cHeight = 195.0;
        #else
            const float cHeight = 195.0 + VOLUMETRIC_CLOUD_DEPTH * 0.5;
        #endif
        float heightToCloud = cHeight - cameraPosition.y;
        if(lightDir.y <= 0.02 || heightToCloud <= 0.0) return 1.0;

        float rayDist = heightToCloud / lightDir.y;
        vec2 sunCloudPos = (cameraPosition.xz + lightDir.xz * rayDist + vec2(fragmentFrameTime, 0.0)) * 0.0625;
        vec2 cData = texelFetch(colortex0, ivec2(sunCloudPos) & 255, 0).xy;

        #ifdef DYNAMIC_CLOUDS
            float fadeTime = saturate(sin(fragmentFrameTime * FADE_SPEED) * 0.8 + 0.5);
            float cloudVal = mix(cData.x, cData.y, fadeTime);
        #else
            float cloudVal = cData.x;
        #endif

        #ifndef FORCE_DISABLE_WEATHER
            #ifdef DYNAMIC_WEATHER
                cloudVal *= smoothstep(0.0, 0.40, weatherFade);
            #endif
        #endif

        float cloudCoverage = smoothstep(0.30, 0.65, cloudVal);
        return 1.0 - smoothstep(0.25, 0.75, cloudCoverage);
    #else
        return 1.0;
    #endif
}

// Ultra-fast Henyey-Greenstein forward-scattering phase function using hardware inversesqrt
float getForwardScatteringPhase(in float cosTheta){
    // g = 0.72, g^2 = 0.5184
    // Precalculated: ((1.0 - 0.5184) / (4.0 * PI)) * 2.2 = 0.084314
    const float hgCoeff = 0.084314;
    float denom = 1.5184 - 1.44 * max(0.0, cosTheta);
    return hgCoeff * inversesqrt(denom * denom * denom);
}

// Evaluates celestial gating including view angle, terrain, clouds, and weather
float getCelestialTotalStrength(in vec3 lightDir, in vec3 lightViewDir, in vec2 lightScreenPos, in float weatherVis){
    if(clamp(lightScreenPos, -0.2, 1.2) != lightScreenPos) return 0.0;
    float terrainVis = getCelestialTerrainVisibility(lightScreenPos);
    if(terrainVis <= 0.001) return 0.0;
    float cloudVis = getCelestialCloudVisibility(lightDir);
    if(cloudVis <= 0.001) return 0.0;
    float viewFade = smoothstep(-0.05, -0.22, lightViewDir.z);
    return GODRAYS_DENSITY * viewFade * (terrainVis * cloudVis * weatherVis);
}

#if WORLD_ID == 1
    #ifndef END_FLASH_UNIFORM_DECLARED
        #define END_FLASH_UNIFORM_DECLARED
        uniform float endFlashIntensity;
        uniform vec3 endFlashPosition;
    #endif
#endif

// Calculates tinted ray color based on celestial strength, water submersion, and skylight
vec3 computeGodrayColor(in float totalStrength, in float sceneDepth){
    vec3 col = lightCol * (shdFade * totalStrength);
    #if WORLD_ID == 1
        float flashRayWeight = smoothstep(0.18, 0.50, endFlashIntensity) * endFlashIntensity;
        col *= flashRayWeight;
    #endif
    if(isEyeInWater == 1){
        vec3 waterTint = mix(toLinear(fogColor), vec3(0.35, 0.75, 0.95), 0.5);
        col = mix(col, waterTint * length(col), 0.65) * 1.4;
    }
    #ifndef WORLD_CUSTOM_SKYLIGHT
        if(sceneDepth < 1.0 && isEyeInWater == 0) col *= smoothstep(0.02, 0.25, eyeBrightFact);
    #endif
    return col;
}

// Samples cloud and terrain transmission for a single point along the ray
float sampleGodrayTransmission(
    in vec2 sampleCoord,
    in vec3 worldDir,
    in float heightToCloud,
    in vec2 camPosOffset,
    in float fadeTime,
    in float weatherCloudMult
){
    vec2 clampedCoord = clamp(sampleCoord, 0.001, 0.999);
    float dTranslucent = textureLod(depthtex0, clampedCoord, 0).x;
    #ifdef DISTANT_HORIZONS
        if(dTranslucent >= 0.99999){
            float dhD = textureLod(dhDepthTex0, clampedCoord, 0).x;
            if(dhD < 1.0) dTranslucent = dhD;
        }
    #elif defined VOXY
        if(dTranslucent >= 0.99999){
            float vxD = textureLod(vxDepthTexOpaque, clampedCoord, 0).x;
            if(vxD > 0.0 && vxD < 1.0) dTranslucent = vxD;
        }
    #endif

    if(dTranslucent >= 0.99999){
        #if CLOUD_TYPE != 0 && !defined FORCE_DISABLE_CLOUDS
            if(heightToCloud > 0.0 && worldDir.y > 0.02){
                vec2 cloudUV = (camPosOffset + worldDir.xz * (heightToCloud / worldDir.y)) * 0.0625;
                vec2 cData = texelFetch(colortex0, ivec2(cloudUV) & 255, 0).xy;
                #ifdef DYNAMIC_CLOUDS
                    float cVal = mix(cData.x, cData.y, fadeTime) * weatherCloudMult;
                #else
                    float cVal = cData.x * weatherCloudMult;
                #endif
                return 1.0 - smoothstep(0.35, 0.65, cVal) * 0.85;
            }
        #endif
        return 1.0;
    }
    #if GODRAYS_WATER_TRANSMISSION == 1
        float dOpaque = textureLod(depthtex1, clampedCoord, 0).x;
        if(dTranslucent < dOpaque) return 0.55;
    #endif
    return 0.0;
}

// Core screen-space raymarching loop with affine world-ray stepping
float marchGodrays(
    in vec2 screenCoord,
    in vec2 stepVec,
    in float dither,
    in vec3 startWorldDir,
    in vec3 stepWorldDir,
    in float heightToCloud,
    in vec2 camPosOffset,
    in float fadeTime,
    in float weatherCloudMult
){
    vec2 sampleCoord = screenCoord + stepVec * dither;
    vec3 sampleWorldDir = startWorldDir + stepWorldDir * dither;

    float accumulatedLight = 0.0;
    float illuminationDecay = 1.0;
    const float decay = 0.90;

    for(int i = 0; i < GODRAY_STEPS; i++){
        sampleCoord += stepVec;
        sampleWorldDir += stepWorldDir;
        float stepTrans = sampleGodrayTransmission(sampleCoord, sampleWorldDir, heightToCloud, camPosOffset, fadeTime, weatherCloudMult);
        accumulatedLight += stepTrans * illuminationDecay;
        illuminationDecay *= decay;
    }

    return accumulatedLight * GODRAY_NORM_FACTOR;
}

// Main entry point for atmospheric godrays
vec3 getGodRays(
    in vec2 screenCoord,
    in vec3 nEyePlayerPos,
    in float dither,
    in float sceneDepth
){
    #if WORLD_ID == 1
        if(endFlashIntensity <= 0.18) return vec3(0.0);
    #endif

    if(GODRAYS_DENSITY <= 0.0 || isEyeInWater == 2 || shdFade <= 0.001) return vec3(0.0);

    #ifndef FORCE_DISABLE_WEATHER
        float weatherVis = 1.0 - smoothstep(0.65, 0.95, weatherFade);
        if(weatherVis <= 0.001) return vec3(0.0);
    #else
        const float weatherVis = 1.0;
    #endif

    vec3 lightDir = vec3(shadowModelView[0].z, shadowModelView[1].z, shadowModelView[2].z);
    vec3 lightViewDir = mat3(gbufferModelView) * lightDir;
    if(lightViewDir.z >= -0.05) return vec3(0.0);

    // Early forward-scattering phase cone culling (skips majority of screen fragments)
    float cosTheta = dot(nEyePlayerPos, lightDir);
    if(cosTheta <= 0.05) return vec3(0.0);

    float phase = getForwardScatteringPhase(cosTheta);

    #ifndef WORLD_CUSTOM_SKYLIGHT
        if(sceneDepth < 1.0 && isEyeInWater == 0 && eyeBrightFact <= 0.02) return vec3(0.0);
    #endif

    vec2 lightScreenPos = getScreenCoord(gbufferProjection, lightViewDir);
    float totalStrength = getCelestialTotalStrength(lightDir, lightViewDir, lightScreenPos, weatherVis);
    if(totalStrength <= 0.001) return vec3(0.0);

    vec3 rayColor = computeGodrayColor(totalStrength, sceneDepth);
    if(max(rayColor.r, max(rayColor.g, rayColor.b)) * phase <= 0.0003) return vec3(0.0);

    vec2 deltaCoord = lightScreenPos - screenCoord;
    float distToLight = length(deltaCoord);
    if(distToLight < 0.0001) return vec3(0.0);

    const float maxRayLength = 0.65;
    vec2 stepVec = deltaCoord * (min(distToLight, maxRayLength) / (distToLight * float(GODRAY_STEPS)));

    #ifdef STORY_MODE_CLOUDS
        const float cHeight = 195.0;
    #else
        const float cHeight = 195.0 + VOLUMETRIC_CLOUD_DEPTH * 0.5;
    #endif
    float heightToCloud = cHeight - cameraPosition.y;
    vec2 camPosOffset = cameraPosition.xz + vec2(fragmentFrameTime, 0.0);

    #ifdef DYNAMIC_CLOUDS
        float fadeTime = saturate(sin(fragmentFrameTime * FADE_SPEED) * 0.8 + 0.5);
    #else
        const float fadeTime = 0.0;
    #endif

    #if !defined FORCE_DISABLE_WEATHER && defined DYNAMIC_WEATHER
        float weatherCloudMult = smoothstep(0.0, 0.40, weatherFade);
    #else
        const float weatherCloudMult = 1.0;
    #endif

    vec3 basisX = (2.0 * gbufferProjectionInverse[0].x) * gbufferModelViewInverse[0].xyz;
    vec3 basisY = (2.0 * gbufferProjectionInverse[1].y) * gbufferModelViewInverse[1].xyz;
    vec3 corner = -gbufferProjectionInverse[0].x * gbufferModelViewInverse[0].xyz - gbufferProjectionInverse[1].y * gbufferModelViewInverse[1].xyz - gbufferModelViewInverse[2].xyz;

    vec3 startWorldDir = corner + basisX * screenCoord.x + basisY * screenCoord.y;
    vec3 stepWorldDir = basisX * stepVec.x + basisY * stepVec.y;

    float accumulatedLight = marchGodrays(screenCoord, stepVec, dither, startWorldDir, stepWorldDir, heightToCloud, camPosOffset, fadeTime, weatherCloudMult);

    return rayColor * (accumulatedLight * phase);
}

#endif // GODRAYS_GLSL
