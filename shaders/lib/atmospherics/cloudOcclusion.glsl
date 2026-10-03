/*
================================ /// Super Duper Vanilla v1.3.8 /// ================================

    Cloud Celestial Occlusion Helper
    Determines optical cloud occlusion along the celestial (sun/moon) light vector
    to dim direct celestial lighting, specular reflections, and celestial disc intensity.

================================ /// Super Duper Vanilla v1.3.8 /// ================================
*/

#ifndef CLOUD_OCCLUSION_GLSL
#define CLOUD_OCCLUSION_GLSL

float getCloudCelestialOcclusion(in vec3 lightDir, in vec3 cameraPos, in float frameTime){
    #ifndef FORCE_DISABLE_WEATHER
        #ifdef DYNAMIC_WEATHER
            if(weatherFade <= 0.001) return 1.0;
        #endif
    #endif

    #if CLOUD_TYPE != 0 && !defined FORCE_DISABLE_CLOUDS
        #ifdef STORY_MODE_CLOUDS
            const float cHeight = 195.0;
        #else
            const float cHeight = 195.0 + VOLUMETRIC_CLOUD_DEPTH * 0.5;
        #endif
        float heightToCloud = cHeight - cameraPos.y;
        if(lightDir.y <= 0.02 || heightToCloud <= 0.0) return 1.0;

        float rayDist = heightToCloud / lightDir.y;
        vec2 sunCloudPos = (cameraPos.xz + lightDir.xz * rayDist + vec2(frameTime, 0.0)) * 0.0625;

        // Filter over the angular width of the celestial disk for smooth transitions
        float r = max(rayDist * (WORLD_SUN_MOON_SIZE * 0.25) * 0.0625, 1.0);
        vec2 c0 = texelFetch(colortex0, ivec2(sunCloudPos) & 255, 0).xy;
        vec2 c1 = texelFetch(colortex0, ivec2(sunCloudPos + vec2(r, 0.0)) & 255, 0).xy;
        vec2 c2 = texelFetch(colortex0, ivec2(sunCloudPos - vec2(r, 0.0)) & 255, 0).xy;
        vec2 c3 = texelFetch(colortex0, ivec2(sunCloudPos + vec2(0.0, r)) & 255, 0).xy;
        vec2 c4 = texelFetch(colortex0, ivec2(sunCloudPos - vec2(0.0, r)) & 255, 0).xy;
        vec2 avgCloud = (c0 * 2.0 + c1 + c2 + c3 + c4) * (1.0 / 6.0);

        #ifdef DYNAMIC_CLOUDS
            float fadeTime = saturate(sin(frameTime * FADE_SPEED) * 0.8 + 0.5);
            float cloudVal = mix(avgCloud.x, avgCloud.y, fadeTime);
        #else
            float cloudVal = avgCloud.x;
        #endif

        #ifndef FORCE_DISABLE_WEATHER
            #ifdef DYNAMIC_WEATHER
                cloudVal *= smoothstep(0.0, 0.40, weatherFade);
            #endif
        #endif

        float cloudCoverage = smoothstep(0.35, 0.65, cloudVal);
        #ifndef FORCE_DISABLE_WEATHER
            #ifdef DYNAMIC_WEATHER
                cloudCoverage = max(cloudCoverage, smoothstep(0.50, 0.90, weatherFade));
            #endif
        #endif

        // When behind a cloud, sun intensity is lowered to ~25%
        return mix(1.0, 0.25, cloudCoverage);
    #else
        return 1.0;
    #endif
}

#endif // CLOUD_OCCLUSION_GLSL
