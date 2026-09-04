vec3 complexShadingDeferred(in vec3 sceneCol, in vec3 screenPos, in vec3 viewPos, in vec3 feetPlayerPos, in vec3 normal, in vec3 albedo, in vec3 dither, in float viewDotInvSqrt, in float metallic, in float smoothness, in bool realSky){
    #if defined ROUGH_REFLECTIONS || defined SSGI
        vec3 noiseUnitVector = generateUnitVector(dither.xy);
    #endif

    // Calculate SSGI
    #ifdef SSGI
        // Get SSGI screen coordinates
        vec3 SSGIcoord = rayTraceScene(screenPos, viewPos, generateCosineVector(normal, noiseUnitVector), dither.z);

        // If sky don't do SSGI
        #ifdef PREVIOUS_FRAME
            if(SSGIcoord.z > 0.5) sceneCol += albedo * texelFetch(colortex5, ivec2(getPrevScreenCoord(SSGIcoord.xy * vec2(pixelWidth, pixelHeight)) * vec2(viewWidth, viewHeight)), 0).rgb;
        #else
            if(SSGIcoord.z > 0.5) sceneCol += albedo * texelFetch(colortex4, ivec2(SSGIcoord.xy), 0).rgb;
        #endif
    #endif

    // If smoothness is 0, return immediately
    if(smoothness < 0.005) return sceneCol;

    #ifdef ROUGH_REFLECTIONS
        // Rough the normals with noise
        normal = generateCosineVector(normal, noiseUnitVector * (squared(1.0 - smoothness) * 0.5));
    #endif

    vec3 nViewPos = viewPos * viewDotInvSqrt;

    // Get reflected view direction
    // reflect(direction, normal) = direction - 2.0 * dot(normal, direction) * normal
    float NV = dot(normal, -nViewPos);
    vec3 reflectViewDir = nViewPos + (2.0 * NV) * normal;
    vec3 reflectPlayerDir = mat3(gbufferModelViewInverse) * reflectViewDir;

    // Calculate SSR and sky reflections
    #ifdef SSR
        // Get SSR screen coordinates
        vec3 SSRCoord = rayTraceScene(screenPos, viewPos, reflectViewDir, dither.z);
        // Check if sky reflection has been hit
        bool isSkyReflection = SSRCoord.z == 1;

        #if defined DISTANT_HORIZONS || defined VOXY
            if(realSky) isSkyReflection = true;
        #endif

        // Fake reflections, also helps with improving reflection quality
        if(isSkyReflection){
            // Using the original ray direction, get the reflected ray and increase its length
            vec3 reflectDirF = viewPos + reflectViewDir * borderFar;

            // This masks only the reflections in view
            if(reflectDirF.z < viewPos.z){
                vec3 SSRDH = getScreenPos(gbufferProjection, reflectDirF);
                // SSRDH.xy *= vec2(viewWidth, viewHeight);
                if(SSRDH.x >= 0 && SSRDH.y >= 0 && SSRDH.x <= 1 && SSRDH.y <= 1 && getDepthTex(SSRDH.xy) != 1) SSRCoord = vec3(SSRDH.xy * vec2(viewWidth, viewHeight), 1);
            }
        }

        #ifdef PREVIOUS_FRAME
            // Get reflections and check for sky
            vec3 reflectCol = isSkyReflection ? getSkyReflection(feetPlayerPos, reflectPlayerDir) : texelFetch(colortex5, ivec2(getPrevScreenCoord(SSRCoord.xy * vec2(pixelWidth, pixelHeight)) * vec2(viewWidth, viewHeight)), 0).rgb;
        #else
            // Get reflections and check for sky
            vec3 reflectCol = isSkyReflection ? getSkyReflection(feetPlayerPos, reflectPlayerDir) : texelFetch(colortex4, ivec2(SSRCoord.xy), 0).rgb;
        #endif
    #else
        vec3 reflectCol = getSkyReflection(feetPlayerPos, reflectViewDir);
    #endif

    // Modified version of BSL's reflection PBR calculation
    // vec3 fresnel = (F0 + (1.0 - F0) * cosTheta) * smoothness
    // Fresnel calculation derived and optimized from this equation
    float smoothCosTheta = NV > 0 ? exp2(-9.28 * NV) * smoothness : smoothness;
    float oneMinusCosTheta = smoothness - smoothCosTheta;

    if(metallic <= 0.9) return sceneCol + reflectCol * (smoothCosTheta + metallic * oneMinusCosTheta);
    return sceneCol + reflectCol * (smoothCosTheta + albedo * oneMinusCosTheta);
}