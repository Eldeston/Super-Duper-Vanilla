vec3 basicShadingForward(in vec3 albedo){
    // Get sky light squared
    float skyLightSquared = squared(lmCoord.y);

    // Calculate sky diffusion first, begining with the sky itself
    // Occlude the appled sky and thunder flash calculation by sky light amount
    vec3 totalDiffuse = (toLinear(SKY_COLOR_DATA_BLOCK) + lightningFlash) * skyLightSquared;

    // Calculate block light
    totalDiffuse += toLinear(squared(lmCoord.x) * blockLightColor * 1.25);

    // Calculate ambient lightning
    totalDiffuse += toLinear(nightVision * 0.5 + AMBIENT_LIGHTING);

    #ifdef WORLD_LIGHT
        #ifdef SHADOW_MAPPING
            // Apply shadow distortion and transform to shadow screen space
            vec3 shdPos = vec3(vertexShdPos.xy / (length(vertexShdPos.xy) * 2.0 + 0.2) + 0.5, vertexShdPos.z);

            // Sample shadows
            #ifdef SHADOW_FILTER
                #if ANTI_ALIASING >= 2
                    float dither = fract(texelFetch(noisetex, ivec2(gl_FragCoord.xy) & 255, 0).x + frameFract) * TAU;
                #else
                    float dither = texelFetch(noisetex, ivec2(gl_FragCoord.xy) & 255, 0).x * TAU;
                #endif

                vec2 randVec = vec2(cos(dither), sin(dither)) * shadowMapPixelSize;

                vec3 shdCol = getShdCol(shdPos, randVec);
            #else
                vec3 shdCol = getShdCol(shdPos);
            #endif

            shdCol *= shdFade;
        #else
            // Sample fake shadows
            float shdCol = saturate(hermiteMix(0.9, 1.0, lmCoord.y)) * shdFade;
        #endif

        #ifndef FORCE_DISABLE_WEATHER
            // Approximate rain diffusing light shadow
            float rainDiffuseAmount = rainStrength * 0.5;

            shdCol *= 1.0 - rainDiffuseAmount;
            shdCol += rainDiffuseAmount * skyLightSquared;
        #endif

        // Calculate and add shadow diffuse
        totalDiffuse += shdCol * toLinear(LIGHT_COLOR_DATA_BLOCK0);
    #endif

    // Return final result
    return albedo.rgb * totalDiffuse;
}