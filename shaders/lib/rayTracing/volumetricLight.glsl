#define VOLUMETRIC_LIGHT_STEPS 8u

vec3 getVolumetricLight(in vec3 nFeetPlayerPos, in float feetPlayerDist, in bool isSky){
    float heightFade = 1.0;

    // Fade VL, but do not apply to underwater VL
    if(isEyeInWater == 0 && nFeetPlayerPos.y > 0){
        heightFade = squared(squared(1.0 - squared(nFeetPlayerPos.y)));
        if(isSky) heightFade *= heightFade;

        #ifndef WORLD_CUSTOM_SKYLIGHT
            #ifndef FORCE_DISABLE_WEATHER
                heightFade += (1.0 - heightFade) * max(1.0 - eyeBrightFact, rainStrength * 0.5);
            #else
                heightFade += (1.0 - heightFade) * (1.0 - eyeBrightFact);
            #endif
        #endif
    }

    #if defined VOLUMETRIC_LIGHTING && defined SHADOW_MAPPING
        // Dithering with interleaved gradient noise
        float dither = IGN(gl_FragCoord.xy, frameCounter);

        // Limit ray distance wherever possible
        float rayDistance = min(shadowDistance, isEyeInWater == 0 ? borderFar : 64.0);
        float rayLength = min(rayDistance, feetPlayerDist);

        // Calculate steps that dynamically increase with distance
        uint dynamicVolumetricLightSteps = clamp(uint(rayLength * VOLUMETRIC_LIGHT_STEPS), 1u, VOLUMETRIC_LIGHT_STEPS);
        float dynamicVolumetricLightStepsInv = 1.0 / dynamicVolumetricLightSteps;

        // Normalize then unormalize with feetPlayerDist and clamping it at minimum distance between far and current shadowDistance
        vec3 endPos = vec3(shadowProjection[0].x, shadowProjection[1].y, shadowProjection[2].z) * (mat3(shadowModelView) * nFeetPlayerPos);
        endPos *= rayLength * dynamicVolumetricLightStepsInv;

        // Apply dithering added to the eyePlayerPos "camera" position converted to shadow clip space
        vec3 startPos = vec3(shadowProjection[0].x, shadowProjection[1].y, shadowProjection[2].z) * shadowModelView[3].xyz + endPos * dither;
        startPos.z += shadowProjection[3].z;

        vec3 volumeData = vec3(0);

        for(uint i = 0u; i < dynamicVolumetricLightSteps; i++){
            // No need to do anymore fancy matrix multiplications during the loop
            volumeData += getShdCol(getShdDistort(startPos));
            // We continue tracing!
            startPos += endPos;
        }
        
        return volumeData * (dynamicVolumetricLightStepsInv * squared(heightFade));
    #else
        return vec3(squared(heightFade));
    #endif
}