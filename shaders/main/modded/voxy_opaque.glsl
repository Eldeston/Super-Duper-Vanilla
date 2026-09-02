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
    layout(location = 0) out vec3 sceneColOut; // colortex4
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

    #ifdef LAVA_NOISE
        #include "/lib/surface/lava.glsl"
    #endif

    #if defined ENVIRONMENT_PBR && !defined FORCE_DISABLE_WEATHER
        #include "/lib/PBR/enviroPBR.glsl"
    #endif

    #include "/lib/utility/projectionFunctions.glsl"

    #include "/lib/modded/distantHorizons+voxy/complexShadingLOD.glsl"

    void voxy_emitFragment(VoxyFragmentParameters parameters){
        // Get screen position
        vec3 screenPos = gl_FragCoord.xyz;
        // Get view position
        vec3 viewPos = getViewPos(vxProjInv, screenPos);
        // Get eye player position
        vec3 feetPlayerPos = mat3(vxModelViewInv) * viewPos + vxModelViewInv[3].xyz;
        // Get world position
        vec3 worldPos = feetPlayerPos + cameraPosition;

        // Prevents overdraw
        if(48000.0 > length(viewPos)){ discard; return; }

        vec3 voxyNormal = vec3(uint((parameters.face >> 1) == 2), uint((parameters.face >> 1) == 0), uint((parameters.face >> 1) == 1)) * (float(int(parameters.face) & 1) * 2 - 1);
        vec2 noiseUv = worldPos.zy * voxyNormal.x + worldPos.xz * voxyNormal.y + worldPos.xy * voxyNormal.z;

        // Declare materials
        dataPBR material;
        material.normal = voxyNormal;
        material.albedo = parameters.sampledColour;

        #if COLOR_MODE == 1
            material.albedo.rgb = vec3(1);
        #elif COLOR_MODE == 2
            material.albedo.rgb = vec3(0);
        #elif COLOR_MODE == 3
            material.albedo.rgb = parameters.sampledColour;
        #endif

        material.smoothness = 0.0; material.emissive = 0.0;
        material.metallic = 0.04; material.porosity = 0.0;
        material.ss = 0.0;
        
        // Currently unused
        material.parallaxShd = 1.0;
        material.ambient = 1.0;

        // If lava
        if(parameters.customId == 11100){
            #ifdef LAVA_NOISE
                // Lava tile size inverse
                const float lavaTileSizeInv = 1.0 / LAVA_TILE_SIZE;

                float lavaNoise = saturate(max(getLavaNoise(noiseUv * lavaTileSizeInv) * 3.0, sumOf(material.albedo.rgb)) - 1.0);
                material.albedo.rgb = floor(material.albedo.rgb * lavaNoise * LAVA_BRIGHTNESS * 32.0) * 0.03125;
            #else
                material.albedo.rgb = material.albedo.rgb * LAVA_BRIGHTNESS;
            #endif

            material.emissive = 1.0;
        }

        // If leaves
        else if((parameters.customId >= 10000 && parameters.customId <= 10800) || (parameters.customId >= 11600 && parameters.customId <= 11799) || parameters.customId == 10900 || parameters.customId == 11101 || parameters.customId == 12200) material.ss = 1.0;

        // Convert to linear space
        material.albedo.rgb = toLinear(material.albedo.rgb);

        #if defined ENVIRONMENT_PBR && !defined FORCE_DISABLE_WEATHER
            if(parameters.customId == 11100) enviroPBR(material, parameters.lightMap, voxyNormal, worldPos);
        #endif

        // Apply simple shading
        sceneColOut = complexShadingLOD(material, parameters.lightMap, feetPlayerPos).rgb;

        // Write buffer datas
        normalDataOut = material.normal;
        albedoDataOut = material.albedo.rgb;
        materialDataOut = vec3(material.metallic, material.smoothness, 0);
    }
#endif