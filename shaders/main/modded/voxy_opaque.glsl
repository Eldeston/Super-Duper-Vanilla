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

    flat in int blockId;

    flat in vec2 lmCoord;

    in float vertexViewDist;

    in vec3 vertexFeetPlayerPos;
    in vec3 vertexWorldPos;

    uniform int isEyeInWater;

    uniform float far;

    uniform float nightVision;
    uniform float lightningFlash;

    #ifndef FORCE_DISABLE_WEATHER
        uniform float rainStrength;
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

    #ifdef LAVA_NOISE
        uniform float fragmentFrameTime;

        #include "/lib/surface/lava.glsl"
    #endif

    #if defined ENVIRONMENT_PBR && !defined FORCE_DISABLE_WEATHER
        uniform float isPrecipitationRain;

        #include "/lib/PBR/enviroPBR.glsl"
    #endif

    #include "/lib/modded/distantHorizons/complexShadingLOD.glsl"

    void voxy_emitFragment(VoxyFragmentParameters parameters){
        // Prevents overdraw
        if(far > vertexViewDist){ discard; return; }

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

        material.smoothness = 0.0; material.emissive = 0.0;
        material.metallic = 0.04; material.porosity = 0.0;
        material.ss = 0.0;
        
        // Currently unused
        material.parallaxShd = 1.0;
        material.ambient = 1.0;

        // If illuminated block
        if(blockId == DH_BLOCK_ILLUMINATED) material.emissive = 1.0;

        // If lava
        else if(blockId == DH_BLOCK_LAVA){
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
        else if(blockId == DH_BLOCK_LEAVES) material.ss = 0.5;

        // Convert to linear space
        material.albedo.rgb = toLinear(material.albedo.rgb);

        #if defined ENVIRONMENT_PBR && !defined FORCE_DISABLE_WEATHER
            if(blockId != DH_BLOCK_LAVA && blockId != DH_BLOCK_ILLUMINATED) enviroPBR(material, voxyNormal);
        #endif

        // Apply simple shading
        sceneColOut = complexShadingLOD(material).rgb;

        // Write buffer datas
        normalDataOut = material.normal;
        albedoDataOut = material.albedo.rgb;
        materialDataOut = vec3(material.metallic, material.smoothness, 0);
    }
#endif