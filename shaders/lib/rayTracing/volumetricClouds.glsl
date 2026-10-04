const uint volumetricCloudSteps = uint(VOLUMETRIC_CLOUD_STEPS);

#ifdef STORY_MODE_CLOUDS
    const float volumetricCenterDepth = VOLUMETRIC_CLOUD_DEPTH * 1.0;
#else
    const float volumetricCenterDepth = VOLUMETRIC_CLOUD_DEPTH * 0.5;
#endif
const float volumetricCloudHeight = 195.0 + volumetricCenterDepth;

#if defined STORY_MODE_CLOUDS && defined SOFT_CLOUD_EDGE
// Bilinear sampling of the 256x256 cloud texture
vec2 sampleCloudMap(in vec2 coord){
    vec2 p = coord - 0.5;
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 w = f * f * (3.0 - 2.0 * f);
    ivec2 i0 = ivec2(i) & 255;
    ivec2 i1 = (i0 + ivec2(1)) & 255;
    vec2 c00 = texelFetch(colortex0, ivec2(i0.x, i0.y), 0).xy;
    vec2 c10 = texelFetch(colortex0, ivec2(i1.x, i0.y), 0).xy;
    vec2 c01 = texelFetch(colortex0, ivec2(i0.x, i1.y), 0).xy;
    vec2 c11 = texelFetch(colortex0, ivec2(i1.x, i1.y), 0).xy;
    return mix(mix(c00, c10, w.x), mix(c01, c11, w.x), w.y);
}
#endif

// This took me a while to finally understand how this all works
vec2 volumetricClouds(in vec3 nFeetPlayerPos, in vec3 cameraPos, in float feetPlayerDist, in float dither, in bool isSky, in bool isCirrus){
    #ifdef STORY_MODE_CLOUDS
        float depth = isCirrus ? (VOLUMETRIC_CLOUD_DEPTH * 0.5) : (VOLUMETRIC_CLOUD_DEPTH * 2.0);
    #else
        float depth = isCirrus ? (VOLUMETRIC_CLOUD_DEPTH * 0.5) : VOLUMETRIC_CLOUD_DEPTH;
    #endif

    // Minimum cloud distance, if terrain, caps distance to the minimum cloud distance
    float cloudFar = isSky ? volumetricCloudFar : min(volumetricCloudFar, feetPlayerDist);
    float invCloudFarSqrd = 1.0 / squared(volumetricCloudFar);

    // Sets the bounding box vertically
    float rcpDirY = 1.0 / nFeetPlayerPos.y;
    float lowerBoundDist = (-depth - cameraPos.y) * rcpDirY;
    float higherBoundDist = -cameraPos.y * rcpDirY;

    // Finds the nearest and furthest plane
    float nearestPlane = max(min(lowerBoundDist, higherBoundDist), 0.0);
	float furthestPlane = min(cloudFar, max(lowerBoundDist, higherBoundDist));

    // If the clouds are outside the bounding box, return nothing
    if(furthestPlane <= nearestPlane || furthestPlane < 0.0) return vec2(0);

    // Get distance inside the cloud
    float distInsideCloud = furthestPlane - nearestPlane;
    if(distInsideCloud <= 0.0) return vec2(0);

    // Calculate cloud steps that dynamically increase with distance
    #ifdef STORY_MODE_CLOUDS
        uint maxCloudSteps = min(uint(VOLUMETRIC_CLOUD_STEPS * 2), 36u);
    #else
        uint maxCloudSteps = volumetricCloudSteps;
    #endif
    uint dynamicVolumetricCloudSteps = max(1u, min(uint(distInsideCloud), maxCloudSteps));
    float volumetricCloudStepsInverse = 1.0 / float(dynamicVolumetricCloudSteps);

    // Multiply by volumetricCloudStepsInverse to get the step size and scale with distance
    float stepDist = distInsideCloud * volumetricCloudStepsInverse;
    vec3 endPos = nFeetPlayerPos * stepDist;

    // Camera position as its start position
    vec3 startPos = cameraPos + nFeetPlayerPos * nearestPlane + endPos * dither;
    float rayDist = nearestPlane + stepDist * dither;

    // To store the cloud data for 2 cloud layers
    vec2 clouds = vec2(0);

    #ifndef FORCE_DISABLE_WEATHER
        #if WORLD_ID == 0
            #ifndef THUNDER_STRENGTH_DECLARED
                #define THUNDER_STRENGTH_DECLARED
                uniform float thunderStrength;
            #endif
            float stormWeatherFade = clamp(max(weatherFade, thunderStrength), 0.0, 1.0);
        #else
            float stormWeatherFade = weatherFade;
        #endif
        #ifdef DYNAMIC_WEATHER
            float overcastDensityMult = isCirrus ? 1.0 : mix(0.85, 1.35, stormWeatherFade);
            float cloudCutoff = isCirrus ? 0.5 : mix(0.5, 0.38, smoothstep(0.35, 0.90, stormWeatherFade));
        #else
            float overcastDensityMult = 1.0;
            float cloudCutoff = 0.5;
        #endif
    #else
        float overcastDensityMult = 1.0;
        float cloudCutoff = 0.5;
    #endif

    #ifdef STORY_MODE_CLOUDS
        float invDepth = 1.0 / depth;
        float playerCloudRelY = cameraPos.y + volumetricCenterDepth;
        float modeBlend = smoothstep(-depth, depth, playerCloudRelY);
    #endif

    // LESSS GOOOOO RAT RACING!!!11!!11!!11!!
    for(uint i = 0u; i < dynamicVolumetricCloudSteps; i++){
        // Get cloud fog using scalar ray distance
        float cloudFog = 1.0 - (rayDist * rayDist) * invCloudFarSqrd;

        // Get cloud texture (lean, stretched wisps for high altitude cirrus)
        vec2 uv = isCirrus ? vec2(startPos.x * 0.02 + startPos.z * 0.008, startPos.z * 0.10) : startPos.xz * 0.0625;

        #ifdef STORY_MODE_CLOUDS
            #ifdef SOFT_CLOUD_EDGE
                vec2 cloudData = sampleCloudMap(uv);
                float covX = smoothstep(cloudCutoff - 0.12, cloudCutoff + 0.12, cloudData.x);
                float covY = smoothstep(cloudCutoff - 0.12, cloudCutoff + 0.12, cloudData.y);
            #else
                vec2 cloudData = texelFetch(colortex0, ivec2(uv) & 255, 0).xy;
                float covX = float(cloudData.x > cloudCutoff);
                float covY = float(cloudData.y > cloudCutoff);
            #endif

            // Bottom-to-top fade when below clouds; top-to-bottom fade when above clouds
            float normY = clamp((startPos.y + depth) * invDepth, 0.0, 1.0);
            float verticalGradient = mix(1.0 - normY, normY, modeBlend);

            // Density scaled purely by vertical gradient, not blown out by overcast multipliers
            float densityScale = (isCirrus ? 4.0 : 8.0) * cloudFog;
            float densityX = covX * verticalGradient * densityScale;
            float densityY = covY * verticalGradient * densityScale;

            clouds.x = max(clouds.x, densityX);
            clouds.y = max(clouds.y, densityY);
        #else
            vec2 cloudData = texelFetch(colortex0, ivec2(uv) & 255, 0).xy;

            // Apply cloud gradiante' (fainter opacity for cirrus clouds)
            float density = (isCirrus ? (-startPos.y * cloudFog * 0.5) : (-startPos.y * cloudFog)) * overcastDensityMult;
            if(cloudData.x > cloudCutoff) clouds.x = max(clouds.x, density);
            if(cloudData.y > cloudCutoff) clouds.y = max(clouds.y, density);
        #endif

        // Continue tracing
        rayDist += stepDist;
        startPos += endPos;
    }

    // Otherwise, return nothing
    return clouds;
}

vec2 volumetricClouds(in vec3 nFeetPlayerPos, in vec3 cameraPos, in float feetPlayerDist, in float dither, in bool isSky){
    return volumetricClouds(nFeetPlayerPos, cameraPos, feetPlayerDist, dither, isSky, false);
}