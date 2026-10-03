/*
================================ /// Super Duper Vanilla v1.3.8 /// ================================

    Atmospheric God Rays (Crepuscular Rays)
    Performant screen-space volumetric light shafts with occlusion from:
    - Terrain / Blocks (depthtex1 & LOD depth)
    - Volumetric & Skybox Clouds (colortex0 cloud density)
    - Water & Translucent Surfaces (depthtex0 vs depthtex1 & underwater rays)
    
    Celestial visibility gating:
    - Zero rays when celestial disk is blocked by terrain, buildings, or hands (depthtex0)
    - Zero rays when celestial disk is occluded by thick clouds or weather overcast
    - Matches lens flare and glare celestial visibility behavior

================================ /// Super Duper Vanilla v1.3.8 /// ================================
*/

#ifndef GODRAYS_GLSL
#define GODRAYS_GLSL

#ifndef PI
    #define PI 3.14159265
#endif

#define GODRAY_STEPS 12

// Checks if the celestial body (sun/moon) is directly visible or occluded by terrain/blocks
float getCelestialTerrainVisibility(in vec2 lightPos){
    // Off-screen celestial body is not directly visible
    if(clamp(lightPos, 0.0, 1.0) != lightPos) return 0.0;

    const vec2 sunOffset = vec2(0.012, 0.012);

    float d0 = textureLod(depthtex0, lightPos, 0).x;
    float d1 = textureLod(depthtex0, lightPos + vec2(sunOffset.x, 0.0), 0).x;
    float d2 = textureLod(depthtex0, lightPos - vec2(sunOffset.x, 0.0), 0).x;
    float d3 = textureLod(depthtex0, lightPos + vec2(0.0, sunOffset.y), 0).x;
    float d4 = textureLod(depthtex0, lightPos - vec2(0.0, sunOffset.y), 0).x;

    #ifdef DISTANT_HORIZONS
        d0 = min(d0, textureLod(dhDepthTex0, lightPos, 0).x);
        d1 = min(d1, textureLod(dhDepthTex0, lightPos + vec2(sunOffset.x, 0.0), 0).x);
        d2 = min(d2, textureLod(dhDepthTex0, lightPos - vec2(sunOffset.x, 0.0), 0).x);
        d3 = min(d3, textureLod(dhDepthTex0, lightPos + vec2(0.0, sunOffset.y), 0).x);
        d4 = min(d4, textureLod(dhDepthTex0, lightPos - vec2(0.0, sunOffset.y), 0).x);
    #elif defined VOXY
        float vx0 = textureLod(vxDepthTexOpaque, lightPos, 0).x;
        float vx1 = textureLod(vxDepthTexOpaque, lightPos + vec2(sunOffset.x, 0.0), 0).x;
        float vx2 = textureLod(vxDepthTexOpaque, lightPos - vec2(sunOffset.x, 0.0), 0).x;
        float vx3 = textureLod(vxDepthTexOpaque, lightPos + vec2(0.0, sunOffset.y), 0).x;
        float vx4 = textureLod(vxDepthTexOpaque, lightPos - vec2(0.0, sunOffset.y), 0).x;
        if(vx0 > 0.0 && vx0 < 1.0) d0 = min(d0, vx0);
        if(vx1 > 0.0 && vx1 < 1.0) d1 = min(d1, vx1);
        if(vx2 > 0.0 && vx2 < 1.0) d2 = min(d2, vx2);
        if(vx3 > 0.0 && vx3 < 1.0) d3 = min(d3, vx3);
        if(vx4 > 0.0 && vx4 < 1.0) d4 = min(d4, vx4);
    #endif

    float v0 = (d0 >= 0.99999) ? 1.0 : 0.0;
    float v1 = (d1 >= 0.99999) ? 1.0 : 0.0;
    float v2 = (d2 >= 0.99999) ? 1.0 : 0.0;
    float v3 = (d3 >= 0.99999) ? 1.0 : 0.0;
    float v4 = (d4 >= 0.99999) ? 1.0 : 0.0;

    return (v0 * 2.0 + v1 + v2 + v3 + v4) * (1.0 / 6.0);
}

// Checks if the celestial disk is covered by clouds along the celestial light vector
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

// Computes cloud optical transmission across sky sample ray
float getCloudSkyTransmission(in vec2 clampedCoord, in float dTranslucent){
    #if CLOUD_TYPE != 0 && !defined FORCE_DISABLE_CLOUDS
        vec3 skySampleViewPos = getViewPos(gbufferProjectionInverse, vec3(clampedCoord, 1.0));
        vec3 skySampleWorldDir = mat3(gbufferModelViewInverse) * skySampleViewPos;
        float worldDirLen = length(skySampleWorldDir);
        vec3 nSkyWorldDir = skySampleWorldDir / max(0.0001, worldDirLen);

        if(nSkyWorldDir.y <= 0.02) return 1.0;

        #ifdef STORY_MODE_CLOUDS
            const float cHeight = 195.0;
        #else
            const float cHeight = 195.0 + VOLUMETRIC_CLOUD_DEPTH * 0.5;
        #endif
        float distToCloud = (cHeight - cameraPosition.y) / nSkyWorldDir.y;
        if(distToCloud <= 0.0) return 1.0;

        vec2 cloudUV = (cameraPosition.xz + nSkyWorldDir.xz * distToCloud + vec2(fragmentFrameTime, 0.0)) * 0.0625;
        vec2 cData = texelFetch(colortex0, ivec2(cloudUV) & 255, 0).xy;

        #ifdef DYNAMIC_CLOUDS
            float fadeTime = saturate(sin(fragmentFrameTime * FADE_SPEED) * 0.8 + 0.5);
            float cVal = mix(cData.x, cData.y, fadeTime);
        #else
            float cVal = cData.x;
        #endif

        #ifndef FORCE_DISABLE_WEATHER
            #ifdef DYNAMIC_WEATHER
                cVal *= smoothstep(0.0, 0.40, weatherFade);
            #endif
        #endif

        float cloudCoverage = smoothstep(0.35, 0.65, cVal);
        return 1.0 - cloudCoverage * 0.85;
    #else
        // In vanilla cloud mode (CLOUD_TYPE == 0), clouds write to depthtex0
        return (dTranslucent < 0.99999) ? 0.15 : 1.0;
    #endif
}

// Samples terrain, water, and cloud occlusion for a single point on screen
float getGodraySampleTransmission(in vec2 sampleCoord){
    vec2 clampedCoord = clamp(sampleCoord, 0.001, 0.999);

    float dOpaque = textureLod(depthtex1, clampedCoord, 0).x;
    #ifdef DISTANT_HORIZONS
        if(dOpaque == 1.0){
            float dhD = textureLod(dhDepthTex0, clampedCoord, 0).x;
            if(dhD < 1.0) dOpaque = dhD;
        }
    #elif defined VOXY
        if(dOpaque == 1.0){
            float vxD = textureLod(vxDepthTexOpaque, clampedCoord, 0).x;
            if(vxD > 0.0 && vxD < 1.0) dOpaque = vxD;
        }
    #endif

    float dTranslucent = textureLod(depthtex0, clampedCoord, 0).x;

    if(dOpaque >= 0.99999){
        return getCloudSkyTransmission(clampedCoord, dTranslucent);
    }
    if(dTranslucent < dOpaque){
        return 0.55;
    }
    return 0.0;
}

// Henyey-Greenstein forward-scattering phase function
float getForwardScatteringPhase(in float cosTheta){
    const float g = 0.72;
    const float g2 = g * g;
    float hg = (1.0 - g2) / pow(1.0 + g2 - 2.0 * g * max(0.0, cosTheta), 1.5) * (1.0 / (4.0 * PI));
    return max(0.0, hg * 2.2);
}

// Main entry point for atmospheric godrays
vec3 getGodRays(
    in vec2 screenCoord,
    in vec3 nEyePlayerPos,
    in float dither,
    in float sceneDepth
){
    if(GODRAYS_DENSITY <= 0.0 || isEyeInWater == 2 || shdFade <= 0.001) return vec3(0.0);

    #ifndef FORCE_DISABLE_WEATHER
        float weatherVis = 1.0 - smoothstep(0.65, 0.95, weatherFade);
        if(weatherVis <= 0.001) return vec3(0.0);
    #else
        const float weatherVis = 1.0;
    #endif

    // Celestial light vector in player/view space
    vec3 lightDir = vec3(shadowModelView[0].z, shadowModelView[1].z, shadowModelView[2].z);
    vec3 lightViewDir = mat3(gbufferModelView) * lightDir;
    if(lightViewDir.z >= -0.05) return vec3(0.0);

    // Light position in screen space [0, 1]
    vec2 lightScreenPos = getScreenCoord(gbufferProjection, lightViewDir);

    // 1. Direct celestial visibility test (terrain / buildings / hand)
    // Godrays must NOT appear when celestial body is occluded behind terrain
    float terrainVis = getCelestialTerrainVisibility(lightScreenPos);
    if(terrainVis <= 0.001) return vec3(0.0);

    // 2. Direct celestial cloud occlusion test
    // Godrays must NOT appear when celestial body is covered by thick clouds
    float cloudVis = getCelestialCloudVisibility(lightDir);
    if(cloudVis <= 0.001) return vec3(0.0);

    float celestialVis = terrainVis * cloudVis * weatherVis;
    if(celestialVis <= 0.001) return vec3(0.0);

    float viewFade = smoothstep(-0.05, -0.22, lightViewDir.z);

    // Screen-space march vector towards light
    vec2 deltaCoord = lightScreenPos - screenCoord;
    float distToLight = length(deltaCoord);
    if(distToLight < 0.0001) return vec3(0.0);

    const float maxRayLength = 0.65;
    float marchDist = min(distToLight, maxRayLength);
    vec2 stepVec = (deltaCoord / distToLight) * (marchDist / float(GODRAY_STEPS));
    vec2 sampleCoord = screenCoord + stepVec * dither;

    // Raymarch loop
    float accumulatedLight = 0.0;
    float illuminationDecay = 1.0;
    const float decay = 0.90;

    for(int i = 0; i < GODRAY_STEPS; i++){
        sampleCoord += stepVec;
        float stepTransmission = getGodraySampleTransmission(sampleCoord);
        accumulatedLight += stepTransmission * illuminationDecay;
        illuminationDecay *= decay;
    }

    const float normFactor = (1.0 - decay) / (1.0 - 0.282429536);
    accumulatedLight *= normFactor;

    // Phase function
    float cosTheta = dot(nEyePlayerPos, lightDir);
    float phase = getForwardScatteringPhase(cosTheta);

    // Base light color
    vec3 rayColor = lightCol * shdFade;

    if(isEyeInWater == 1){
        vec3 waterTint = mix(toLinear(fogColor), vec3(0.35, 0.75, 0.95), 0.5);
        rayColor = mix(rayColor, waterTint * length(rayColor), 0.65) * 1.4;
    }

    #ifndef WORLD_CUSTOM_SKYLIGHT
        if(sceneDepth < 1.0 && isEyeInWater == 0){
            rayColor *= smoothstep(0.02, 0.25, eyeBrightFact);
        }
    #endif

    float totalStrength = GODRAYS_DENSITY * viewFade * celestialVis;
    return rayColor * (accumulatedLight * phase * totalStrength);
}

#endif // GODRAYS_GLSL
