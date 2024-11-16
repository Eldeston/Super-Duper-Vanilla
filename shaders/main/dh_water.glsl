/*
================================ /// Super Duper Vanilla v1.3.7 /// ================================

    Developed by Eldeston, presented by FlameRender (C) Studios.

    Copyright (C) 2023 Eldeston | FlameRender (C) Studios License


    By downloading this content you have agreed to the license and its terms of use.

================================ /// Super Duper Vanilla v1.3.7 /// ================================
*/

/// Buffer features: TAA jittering, simple shading, and world curvature

/// -------------------------------- /// Vertex Shader /// -------------------------------- ///

#ifdef VERTEX
    flat out int blockId;

    flat out vec2 lmCoord;

    flat out vec3 vertexNormal;

    out vec2 waterNoiseUv;

    out vec3 vertexColor;
    out vec3 vertexFeetPlayerPos;

    uniform vec3 cameraPosition;

    uniform mat4 gbufferModelViewInverse;

    uniform mat4 dhProjection;

    #ifdef WORLD_CURVATURE
        uniform mat4 gbufferModelView;
    #endif

    #ifdef WORLD_LIGHT
        uniform mat4 shadowModelView;

        #ifdef SHADOW_MAPPING
            uniform mat4 shadowProjection;
        #endif
    #endif

    #if ANTI_ALIASING == 2
        uniform int frameMod;

        uniform float pixelWidth;
        uniform float pixelHeight;

        #include "/lib/utility/taaJitter.glsl"
    #endif
    
    void main(){
        // Distant horizons terrain color is stored here
        vertexColor = gl_Color.rgb;

        // Distant horizons lightmap calculation
        #ifdef WORLD_CUSTOM_SKYLIGHT
            lmCoord = vec2(min(gl_MultiTexCoord2.x, 1.0), WORLD_CUSTOM_SKYLIGHT);
        #else
            lmCoord = min(gl_MultiTexCoord2.xy, vec2(1));
        #endif

        // Get vertex normal
        vertexNormal = mat3(gbufferModelViewInverse) * (gl_NormalMatrix * fastNormalize(gl_Normal));

        // Get vertex view position
        vec3 vertexViewPos = mat3(gl_ModelViewMatrix) * gl_Vertex.xyz + gl_ModelViewMatrix[3].xyz;
        // Get vertex feet player position
        vertexFeetPlayerPos = mat3(gbufferModelViewInverse) * vertexViewPos + gbufferModelViewInverse[3].xyz;

        // Get world position
        vec3 vertexWorldPos = vertexFeetPlayerPos + cameraPosition;

        // Get water noise uv position
        waterNoiseUv = vertexWorldPos.xz * waterTileSizeInv;

        if(dhMaterialId == DH_BLOCK_WATER) blockId = 2;

	    #ifdef WORLD_CURVATURE
            // Apply curvature distortion
            vertexFeetPlayerPos.y -= lengthSquared(vertexFeetPlayerPos.xz) * worldCurvatureInv;

            // Convert back to vertex view position
            vertexViewPos = mat3(gbufferModelView) * vertexFeetPlayerPos + gbufferModelView[3].xyz;
        #endif

        // Convert to clip position and output as final position
        // gl_Position = dhProjection * vertexViewPos;
        gl_Position.xyz = getMatScale(mat3(dhProjection)) * vertexViewPos;
        gl_Position.z += dhProjection[3].z;

        gl_Position.w = -vertexViewPos.z;

        #if ANTI_ALIASING == 2
            gl_Position.xy += jitterPos(gl_Position.w);
        #endif
    }
#endif

/// -------------------------------- /// Fragment Shader /// -------------------------------- ///

#ifdef FRAGMENT
    /* RENDERTARGETS: 0,1,2,3 */
    layout(location = 0) out vec4 sceneColOut; // gcolor
    layout(location = 1) out vec4 normalDataOut; // colortex1
    layout(location = 2) out vec4 albedoDataOut; // colortex2
    layout(location = 3) out vec4 materialDataOut; // colortex3

    flat in int blockId;

    flat in vec2 lmCoord;

    flat in vec3 vertexNormal;

    in vec2 waterNoiseUv;

    in vec3 vertexColor;
    in vec3 vertexFeetPlayerPos;

    uniform int isEyeInWater;

    uniform float nightVision;

    uniform mat4 gbufferProjectionInverse;

    uniform sampler2D depthtex1;
    uniform sampler2D dhDepthTex1;

    #ifdef IS_IRIS
        uniform float lightningFlash;
    #endif

    #ifndef FORCE_DISABLE_WEATHER
        uniform float rainStrength;
    #endif

    #if defined SHADOW_FILTER && ANTI_ALIASING >= 2
        uniform float frameFract;
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

    #include "/lib/utility/projectionFunctions.glsl"

    #ifdef WORLD_LIGHT
        uniform float shdFade;

        uniform mat4 shadowModelView;

        #ifdef SHADOW_MAPPING
            uniform mat4 shadowProjection;

            #include "/lib/lighting/shdMapping.glsl"
        #endif

        #include "/lib/lighting/GGX.glsl"
    #endif

    #include "/lib/PBR/dataStructs.glsl"

    #include "/lib/utility/noiseFunctions.glsl"

    #if defined WATER_NORMAL || defined WATER_NOISE
        uniform float fragmentFrameTime;

        #include "/lib/surface/water.glsl"
    #endif

    #include "/lib/lighting/complexShadingForward.glsl"

    void main(){
        // Fix for Distant Horizons translucents rendering over real geometry
        if(texelFetch(depthtex1, ivec2(gl_FragCoord.xy), 0).x != 1.0){ discard; return; }

        // Declare materials
	    dataPBR material;
        material.normal = vertexNormal;
        material.albedo = vec4(vertexColor, 1);

        #if COLOR_MODE == 1
            material.albedo.rgb = vec3(1);
        #elif COLOR_MODE == 2
            material.albedo.rgb = vec3(0);
        #endif

        material.smoothness = 0.96; material.emissive = 0.0;
        material.metallic = 0.04; material.porosity = 0.0;
        material.ss = 0.0; material.parallaxShd = 1.0;
        material.ambient = 1.0;

        // If water
        if(blockId == 2){
            float waterNoise = WATER_BRIGHTNESS;

            #ifdef WATER_NORMAL
                vec4 waterData = H2NWater(waterNoiseUv).xzyw;
                material.normal = fastNormalize(waterData.yxz * vertexNormal.x + waterData.xyz * vertexNormal.y + waterData.xzy * vertexNormal.z);

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

        // Apply simple shading
        sceneColOut = vec4(complexShadingForward(material), 1);
    
        // Write buffer datas
        normalDataOut = vec4(material.normal, 1);
        albedoDataOut = vec4(material.albedo.rgb, 1);
        materialDataOut = vec4(material.metallic, material.smoothness, 0.5, 1);
    }
#endif