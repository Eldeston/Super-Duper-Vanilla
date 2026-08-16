/*
================================ /// Super Duper Vanilla v1.3.9 /// ================================

    Developed by Eldeston, presented by FlameRender (C) Studios.

    Copyright (C) 2025 Eldeston | FlameRender (C) Studios License


    By downloading this content you have agreed to the license and its terms of use.

================================ /// Super Duper Vanilla v1.3.9 /// ================================
*/

/// Buffer features: TAA jittering, complex shading, animation, water noise, PBR, and world curvature

/// -------------------------------- /// Vertex Shader /// -------------------------------- ///

#ifdef VERTEX
    flat out int blockId;

    out vec2 lmCoord;
    out vec2 texCoord;
    out vec2 waterNoiseUv;

    out vec3 vertexColor;
    out vec3 vertexFeetPlayerPos;
    out vec3 vertexWorldPos;

    out mat3 TBN;

    #if defined NORMAL_GENERATION || defined PARALLAX_OCCLUSION
        flat out vec2 vTexCoordScale;
        flat out vec2 vTexCoordPos;

        out vec2 vTexCoord;
    #endif

    uniform vec3 cameraPosition;

    uniform mat4 gbufferModelViewInverse;

    #if defined WATER_ANIMATION || defined WORLD_CURVATURE
        uniform mat4 gbufferModelView;
    #endif
    
    #if ANTI_ALIASING == 2
        uniform int frameMod;

        uniform float pixelWidth;
        uniform float pixelHeight;

        #include "/lib/utility/taaJitter.glsl"
    #endif

    #ifdef WATER_ANIMATION
        uniform float vertexFrameTime;

        #include "/lib/vertex/waveWater.glsl"
    #endif

    attribute vec3 mc_Entity;

    attribute vec4 at_tangent;

    #if defined NORMAL_GENERATION || defined PARALLAX_OCCLUSION
        attribute vec2 mc_midTexCoord;
    #endif

    void main(){
        // Get block id
        blockId = int(mc_Entity.x);
        // Get buffer texture coordinates
        texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
        // Get vertex color
        vertexColor = gl_Color.rgb;

        // Lightmap fix for mods
        #ifdef WORLD_CUSTOM_SKYLIGHT
            lmCoord = vec2(lightMapCoord(gl_MultiTexCoord1.x), WORLD_CUSTOM_SKYLIGHT);
        #else
            lmCoord = lightMapCoord(gl_MultiTexCoord1.xy);
        #endif

        // Get vertex normal
        vec3 vertexNormal = fastNormalize(gl_Normal);
        // Get vertex tangent
        vec3 vertexTangent = fastNormalize(at_tangent.xyz);

        // Get vertex view position
        vec3 vertexViewPos = mat3(gl_ModelViewMatrix) * gl_Vertex.xyz + gl_ModelViewMatrix[3].xyz;
        // Get vertex feet player position
        vertexFeetPlayerPos = mat3(gbufferModelViewInverse) * vertexViewPos + gbufferModelViewInverse[3].xyz;

        // Get world position
        vertexWorldPos = vertexFeetPlayerPos + cameraPosition;

        // Get water noise uv position
        waterNoiseUv = vertexWorldPos.xz * waterTileSizeInv;

        // Calculate TBN matrix
        TBN = mat3(gbufferModelViewInverse) * (gl_NormalMatrix * mat3(vertexTangent, cross(vertexTangent, vertexNormal) * sign(at_tangent.w), vertexNormal));

        #if defined NORMAL_GENERATION || defined PARALLAX_OCCLUSION
            vec2 midCoord = (gl_TextureMatrix[0] * vec4(mc_midTexCoord, 0, 0)).xy;
            vec2 texMinMidCoord = texCoord - midCoord;

            vTexCoordScale = abs(texMinMidCoord) * 2.0;
            vTexCoordPos = min(texCoord, midCoord - texMinMidCoord);
            vTexCoord = sign(texMinMidCoord) * 0.5 + 0.5;
        #endif

        #ifdef WATER_ANIMATION
            vertexFeetPlayerPos = getWaterWave(vertexFeetPlayerPos, vertexWorldPos.xz, mc_Entity.x, vertexFrameTime);
        #endif

        #ifdef WORLD_CURVATURE
            // Apply curvature distortion
            vertexFeetPlayerPos.y -= dot(vertexFeetPlayerPos.xz, vertexFeetPlayerPos.xz) * worldCurvatureInv;
        #endif

        #if defined WATER_ANIMATION || defined WORLD_CURVATURE
            // Convert back to vertex view position
            vertexViewPos = mat3(gbufferModelView) * vertexFeetPlayerPos + gbufferModelView[3].xyz;
        #endif

        // Convert to clip position and output as final position
        // gl_Position = gl_ProjectionMatrix * vertexViewPos;
        gl_Position.xyz = getMatScale(mat3(gl_ProjectionMatrix)) * vertexViewPos;
        gl_Position.z += gl_ProjectionMatrix[3].z;

        gl_Position.w = -vertexViewPos.z;

        #if ANTI_ALIASING == 2
            gl_Position.xy += jitterPos(gl_Position.w);
        #endif
    }
#endif

/// -------------------------------- /// Fragment Shader /// -------------------------------- ///

#ifdef FRAGMENT
    /* RENDERTARGETS: 4,1,2,3 */
    layout(location = 0) out vec4 sceneColOut; // colortex4
    layout(location = 1) out vec3 normalDataOut; // colortex1
    layout(location = 2) out vec3 albedoDataOut; // colortex2
    layout(location = 3) out vec3 materialDataOut; // colortex3

    flat in int blockId;

    in vec2 lmCoord;
    in vec2 texCoord;
    in vec2 waterNoiseUv;

    in vec3 vertexColor;
    in vec3 vertexFeetPlayerPos;
    in vec3 vertexWorldPos;

    in mat3 TBN;

    #if defined NORMAL_GENERATION || defined PARALLAX_OCCLUSION
        flat in vec2 vTexCoordScale;
        flat in vec2 vTexCoordPos;

        in vec2 vTexCoord;
    #endif

    uniform int isEyeInWater;

    uniform float nightVision;
    uniform float lightningFlash;

    uniform float near;

    uniform sampler2D depthtex1;
    uniform sampler2D gtexture;

    #ifndef FORCE_DISABLE_WEATHER
        uniform float rainStrength;
    #endif

    #if defined SHADOW_FILTER && ANTI_ALIASING >= 2
        uniform float frameFract;
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

        #ifdef SHADOW_MAPPING
            uniform mat4 shadowProjection;

            #include "/lib/lighting/shdDistort.glsl"
            #include "/lib/lighting/shdSample.glsl"
        #endif

        #include "/lib/lighting/GGX.glsl"
    #endif

    #include "/lib/PBR/dataStructs.glsl"

    #if PBR_MODE <= 1
        #include "/lib/PBR/integratedPBR.glsl"
    #else
        #include "/lib/PBR/labPBR.glsl"
    #endif

    #include "/lib/utility/noiseFunctions.glsl"

    #if defined WATER_NORMAL || defined WATER_NOISE
        uniform float fragmentFrameTime;

        #include "/lib/surface/water.glsl"
    #endif

    #if defined ENVIRONMENT_PBR && !defined FORCE_DISABLE_WEATHER
        uniform float isPrecipitationRain;

        #include "/lib/PBR/enviroPBR.glsl"
    #endif

    #include "/lib/lighting/complexShadingForward.glsl"

    void main(){
        // Declare materials
        dataPBR material;
        getPBR(material, blockId);
        
        // Alpha test, discard and return immediately
        if(material.albedo.a < ALPHA_THRESHOLD){ discard; return; }

        if(blockId == 11102 || blockId == 12100){
            // Fast depth linearization by DrDesten
            // Not great, but plausible for most scenarios
            float blockDepth = near / (1.0 - gl_FragCoord.z) - near / (1.0 - getDepth(depthtex1, ivec2(gl_FragCoord.xy), 0));
            // Get the depth outline for the end portal
            float edgeBrightness = exp2((blockDepth + 0.0625) * 8.0);

            // Water
            if(blockId == 11102){
                float waterNoise = WATER_BRIGHTNESS;

                #if defined WATER_NORMAL
                    vec4 waterData = H2NWater(waterNoiseUv).xzyw;
                    material.normal = fastNormalize(waterData.yxz * TBN[2].x + waterData.xyz * TBN[2].y + waterData.xzy * TBN[2].z);

                    #ifdef WATER_NOISE
                        waterNoise *= squared(0.128 + waterData.w * 0.5);
                    #endif
                #elif defined WATER_NOISE
                    float waterData = getCellNoise(waterNoiseUv);

                    waterNoise *= squared(0.128 + waterData * 0.5);
                #endif

                #ifdef WATER_STYLIZE_ABSORPTION
                    if(isEyeInWater == 0){
                        float depthBrightness = exp2(blockDepth * 0.25);
                        material.albedo.rgb = material.albedo.rgb * (waterNoise * (1.0 - depthBrightness) + depthBrightness);
                        material.albedo.a = fastSqrt(material.albedo.a) * (1.0 - depthBrightness);
                    }
                    else material.albedo.rgb *= waterNoise;
                #else
                    material.albedo.rgb *= waterNoise;
                #endif

                #ifdef WATER_FOAM
                    material.albedo = min(vec4(1), material.albedo + edgeBrightness);
                #endif
            }

            // Nether portal
            else material.albedo.rgb = min(vec3(1), material.albedo.rgb * (0.5 + edgeBrightness * 2.0));
        }

        material.albedo.rgb = toLinear(material.albedo.rgb);

        #if defined ENVIRONMENT_PBR && !defined FORCE_DISABLE_WEATHER
            if(blockId != 11102) enviroPBR(material, TBN[2]);
        #endif

        // Write to HDR scene color
        sceneColOut = complexShadingForward(material);

        // Write buffer datas
        normalDataOut = material.normal;
        albedoDataOut = material.albedo.rgb;
        materialDataOut = vec3(material.metallic, material.smoothness, 0.5);
    }
#endif