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

    flat in int blockId;

    flat in vec2 lmCoord;

    in float vertexViewDist;

    in vec2 waterNoiseUv;

    in vec3 vertexFeetPlayerPos;
    in vec3 vertexWorldPos;

    uniform int isEyeInWater;

    uniform float far;

    uniform float nightVision;
    uniform float lightningFlash;

    uniform mat4 gbufferProjectionInverse;

    uniform sampler2D depthtex0;
    uniform sampler2D dhDepthTex1;

    #ifndef FORCE_DISABLE_WEATHER
        uniform float rainStrength;
    #endif

    #if defined WATER_STYLIZE_ABSORPTION || defined WATER_FOAM
        uniform float dhNearPlane;
    #endif

    #ifndef FORCE_DISABLE_DAY_CYCLE
        uniform float dayCycle;
        uniform float twilightPhase;
    #endif

    #ifdef WORLD_VANILLA_FOG_COLOR
        uniform vec3 fogColor;
    #endif

    #ifdef WORLD_CUSTOM_SKYLIGHT
        const float eyeBrightFact = WORLD_CUSTOM_SKYLIGHT;
    #else
        uniform float eyeSkylight;
        
        float eyeBrightFact = eyeSkylight;
    #endif

    #ifdef WORLD_LIGHT
        uniform float shdFade;

        uniform mat4 shadowModelView;

        #include "/lib/lighting/GGX.glsl"
    #endif

    #include "/lib/PBR/dataStructs.glsl"

    #include "/lib/utility/noiseFunctions.glsl"

    #if defined WATER_NORMAL || defined WATER_NOISE
        uniform float fragmentFrameTime;

        #include "/lib/surface/water.glsl"
    #endif

    #if defined ENVIRONMENT_PBR && !defined FORCE_DISABLE_WEATHER
        uniform float isPrecipitationRain;

        #include "/lib/PBR/enviroPBR.glsl"
    #endif

    #include "/lib/modded/distantHorizons/complexShadingLOD.glsl"

    void voxy_emitFragment(VoxyFragmentParameters parameters){
        // Prevents overdraw
        if(far > vertexViewDist){ discard; return; }

        // Fix for Distant Horizons translucents rendering over real geometry
        if(getDepth(depthtex0, ivec2(gl_FragCoord.xy), 0) != 1.0){ discard; return; }

        vec3 voxyNormal = vec3(uint((face >> 1) == 2), uint((face >> 1) == 0), uint((face >> 1) == 1)) * (float(int(face) & 1) * 2 - 1);
        vec2 noiseUv = vertexWorldPos.zy * voxyNormal.x + vertexWorldPos.xz * voxyNormal.y + vertexWorldPos.xy * voxyNormal.z;
        vec2 noiseCol = texelFetch(noisetex, ivec2(noiseUv * 4.0) & 255, 0).xy;
        float dhNoise = (noiseCol.x + noiseCol.y) * 0.2 + 0.8;

        // Declare materials
        dataPBR material;
        material.normal = voxyNormal;
        material.albedo = vec4(min(parameters.sampledColour * dhNoise, vec3(1)), 1);

        #if COLOR_MODE == 1
            material.albedo.rgb = vec3(1);
        #elif COLOR_MODE == 2
            material.albedo.rgb = vec3(0);
        #elif COLOR_MODE == 3
            material.albedo.rgb = parameters.sampledColour;
        #endif

        material.smoothness = 0.96; material.emissive = 0.0;
        material.metallic = 0.04; material.porosity = 0.0;
        material.ss = 0.0;
        
        // Currently unused
        material.parallaxShd = 1.0;
        material.ambient = 1.0;

        // If water
        if(blockId == DH_BLOCK_WATER){
            float waterNoise = WATER_BRIGHTNESS;

            #ifdef WATER_NORMAL
                vec4 waterData = H2NWater(waterNoiseUv).xzyw;
                material.normal = fastNormalize(waterData.yxz * voxyNormal.x + waterData.xyz * voxyNormal.y + waterData.xzy * voxyNormal.z);

                #ifdef WATER_NOISE
                    waterNoise *= squared(0.128 + waterData.w * 0.5);
                #endif
            #elif defined WATER_NOISE
                float waterData = getCellNoise(waterNoiseUv);

                waterNoise *= squared(0.128 + waterData * 0.5);
            #endif

            #if defined WATER_STYLIZE_ABSORPTION || defined WATER_FOAM
                // Water color and foam. Fast depth linearization by DrDesten
                float waterDepth = dhNearPlane / (1.0 - gl_FragCoord.z) - dhNearPlane / (1.0 - texelFetch(dhDepthTex1, ivec2(gl_FragCoord.xy), 0).x);
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
            if(blockId != DH_BLOCK_WATER) enviroPBR(material, voxyNormal);
        #endif

        // Apply simple shading
        sceneColOut = complexShadingLOD(material);
    
        // Write buffer datas
        normalDataOut = material.normal;
        albedoDataOut = material.albedo.rgb;
        materialDataOut = vec3(material.metallic, material.smoothness, 0.5);
    }
#endif