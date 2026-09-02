/*
================================ /// Super Duper Vanilla v1.3.9 /// ================================

    Developed by Eldeston, presented by FlameRender (C) Studios.

    Copyright (C) 2025 Eldeston | FlameRender (C) Studios License


    By downloading this content you have agreed to the license and its terms of use.

================================ /// Super Duper Vanilla v1.3.9 /// ================================
*/

/// Buffer features: TAA jittering, simple shading, and world curvature

/// -------------------------------- /// Fragment Shader /// -------------------------------- ///

#ifdef FRAGMENT
    /* RENDERTARGETS: 4,1,2,3 */
    layout(location = 0) out vec4 sceneColOut; // colortex4
    layout(location = 1) out vec3 normalDataOut; // colortex1
    layout(location = 2) out vec3 albedoDataOut; // colortex2
    layout(location = 3) out vec3 materialDataOut; // colortex3

    #ifdef WORLD_CUSTOM_SKYLIGHT
        const float eyeBrightFact = WORLD_CUSTOM_SKYLIGHT;
    #else
        float eyeBrightFact = eyeSkylight;
    #endif

    #ifdef WORLD_LIGHT
        #include "/lib/lighting/GGX.glsl"
    #endif

    #include "/lib/PBR/dataStructs.glsl"

    #if defined WATER_NORMAL || defined WATER_NOISE
        #include "/lib/surface/water.glsl"
    #endif

    #if defined ENVIRONMENT_PBR && !defined FORCE_DISABLE_WEATHER
        #include "/lib/PBR/enviroPBR.glsl"
    #endif

    #include "/lib/utility/projectionFunctions.glsl"

    #include "/lib/modded/distantHorizons+voxy/complexShadingLOD.glsl"

    void voxy_emitFragment(VoxyFragmentParameters parameters){
        // Get screen position
        vec3 screenPos = vec3(gl_FragCoord.x * pixelWidth, gl_FragCoord.y * pixelHeight, gl_FragCoord.z);
        // Get view position
        vec3 viewPos = getViewPos(vxProjInv, screenPos);
        // Get eye player position
        vec3 feetPlayerPos = mat3(vxModelViewInv) * viewPos + vxModelViewInv[3].xyz;
        // Get world position
        vec3 worldPos = feetPlayerPos + cameraPosition;

        // Prevents overdraw
        if(far > length(viewPos)){ discard; return; }

        // Fix for Distant Horizons translucents rendering over real geometry
        if(getDepth(depthtex0, ivec2(gl_FragCoord.xy), 0) != 1.0){ discard; return; }

        vec3 voxyNormal = vec3(uint((parameters.face >> 1) == 2), uint((parameters.face >> 1) == 0), uint((parameters.face >> 1) == 1)) * (float(int(parameters.face) & 1) * 2 - 1);

        // Declare materials
        dataPBR material;
        material.normal = voxyNormal;
        material.albedo = parameters.sampledColour * parameters.tinting;

        #if COLOR_MODE == 1
            material.albedo.rgb = vec3(1);
        #elif COLOR_MODE == 2
            material.albedo.rgb = vec3(0);
        #elif COLOR_MODE == 3
            material.albedo.rgb = parameters.tinting;
        #endif

        material.smoothness = 0.0; material.emissive = 0.0;
        material.metallic = 0.04; material.porosity = 0.0;
        material.ss = 0.0;
        
        // Currently unused
        material.parallaxShd = 1.0;
        material.ambient = 1.0;

        // If water
        // Do nether portal later
        if(parameters.customId == 11102){
            material.smoothness = 0.96;

            float waterNoise = WATER_BRIGHTNESS;

            #ifdef WATER_NORMAL
                vec4 waterData = H2NWater(worldPos.xz * waterTileSizeInv).xzyw;
                material.normal = fastNormalize(waterData.yxz * voxyNormal.x + waterData.xyz * voxyNormal.y + waterData.xzy * voxyNormal.z);

                #ifdef WATER_NOISE
                    waterNoise *= squared(0.128 + waterData.w * 0.5);
                #endif
            #elif defined WATER_NOISE
                float waterData = getCellNoise(worldPos.xz * waterTileSizeInv);

                waterNoise *= squared(0.128 + waterData * 0.5);
            #endif

            #if defined WATER_STYLIZE_ABSORPTION || defined WATER_FOAM
                // Water color and foam. Fast depth linearization by DrDesten
                float waterDepth = 16.0 / (1.0 - gl_FragCoord.z) - 16.0 / (1.0 - texelFetch(vxDepthTexTrans, ivec2(gl_FragCoord.xy), 0).x);
            #endif

            #ifdef WATER_STYLIZE_ABSORPTION
                if(isEyeInWater == 0){
                    float depthBrightness = exp2(waterDepth * 0.25);
                    material.albedo.rgb = material.albedo.rgb * (waterNoise * (1.0 - depthBrightness) + depthBrightness);
                    material.albedo.a = fastSqrt(material.albedo.a) * (1.0 - depthBrightness);
                }
                else material.albedo.rgb *= waterNoise;
            #else
                material.albedo.rgb *= waterNoise;
            #endif

            #ifdef WATER_FOAM
                material.albedo = min(vec4(1), material.albedo + exp2((waterDepth + 0.0625) * 8.0));
            #endif
        }

        // Convert to linear space
        material.albedo.rgb = toLinear(material.albedo.rgb);

        #if defined ENVIRONMENT_PBR && !defined FORCE_DISABLE_WEATHER
            if(parameters.customId == 11102) enviroPBR(material, parameters.lightMap, voxyNormal, worldPos);
        #endif

        // Voxy lightmap calculation
        #ifdef WORLD_CUSTOM_SKYLIGHT
            vec2 voxyLightMap = vec2(min((parameters.lightMap.x - 0.03125) * 1.06666667, 1.0), WORLD_CUSTOM_SKYLIGHT);
        #else
            vec2 voxyLightMap = min((parameters.lightMap.xy - 0.03125) * 1.06666667, vec2(1));
        #endif

        // Apply simple shading
        sceneColOut = complexShadingLOD(material, voxyLightMap, feetPlayerPos);
    
        // Write buffer datas
        normalDataOut = material.normal;
        albedoDataOut = material.albedo.rgb;
        materialDataOut = vec3(material.metallic, material.smoothness, 0.5);
    }
#endif