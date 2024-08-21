/*
================================ /// Super Duper Vanilla v1.3.6 /// ================================

    Developed by Eldeston, presented by FlameRender (C) Studios.

    Copyright (C) 2023 Eldeston | FlameRender (C) Studios License


    By downloading this content you have agreed to the license and its terms of use.

================================ /// Super Duper Vanilla v1.3.6 /// ================================
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

    out mat3 TBN;

    #if defined NORMAL_GENERATION || defined PARALLAX_OCCLUSION
        flat out vec2 vTexCoordScale;
        flat out vec2 vTexCoordPos;

        out vec2 vTexCoord;
    #endif

    #ifdef PHYSICS_OCEAN
        // Physics mod varyings
        out float physics_localWaviness;

        out vec2 physics_localPosition;

        #include "/lib/modded/physicsMod/physicsModVertex.glsl"
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

        #include "/lib/vertex/waterWave.glsl"
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
            lmCoord = vec2(min(gl_MultiTexCoord1.x * 0.00416667, 1.0), WORLD_CUSTOM_SKYLIGHT);
        #else
            lmCoord = min(gl_MultiTexCoord1.xy * 0.00416667, vec2(1));
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
        vec3 vertexWorldPos = vertexFeetPlayerPos + cameraPosition;

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

        #ifdef PHYSICS_OCEAN
            // Physics mod vertex displacement
            if(mc_Entity.x == 11102){
                // pass this to the fragment shader to fetch the texture there for per fragment normals
                physics_localPosition = (gl_Vertex.xz - physics_waveOffset) * PHYSICS_XZ_SCALE * physics_oceanWaveHorizontalScale;

                // basic texture to determine how shallow/far away from the shore the water is
                physics_localWaviness = texelFetch(physics_waviness, ivec2(gl_Vertex.xz) - physics_textureOffset, 0).r;

                // transform gl_Vertex (since it is the raw mesh, i.e. not transformed yet)
                vertexFeetPlayerPos.y += physics_waveHeight(physics_localPosition, physics_localWaviness);
            }
        #endif

        #ifdef WATER_ANIMATION
            // Apply water wave animation
            if(mc_Entity.x == 11102 && CURRENT_SPEED > 0) vertexFeetPlayerPos.y = getWaterWave(vertexWorldPos.xz, vertexFeetPlayerPos.y, vertexFrameTime);
        #endif

        #ifdef WORLD_CURVATURE
            // Apply curvature distortion
            vertexFeetPlayerPos.y -= dot(vertexFeetPlayerPos.xz, vertexFeetPlayerPos.xz) * worldCurvatureInv;
        #endif

        #if defined WATER_ANIMATION || defined WORLD_CURVATURE || defined PHYSICS_OCEAN
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
    /* RENDERTARGETS: 0,1,2,3 */
    layout(location = 0) out vec4 sceneColOut; // gcolor
    layout(location = 1) out vec3 normalDataOut; // colortex1
    layout(location = 2) out vec3 albedoDataOut; // colortex2
    layout(location = 3) out vec3 materialDataOut; // colortex3

    flat in int blockId;

    in vec2 lmCoord;
    in vec2 texCoord;
    in vec2 waterNoiseUv;

    in vec3 vertexColor;
    in vec3 vertexFeetPlayerPos;

    in mat3 TBN;

    #if defined NORMAL_GENERATION || defined PARALLAX_OCCLUSION
        flat in vec2 vTexCoordScale;
        flat in vec2 vTexCoordPos;

        in vec2 vTexCoord;
    #endif

    #ifdef PHYSICS_OCEAN
        // Physics mod varyings
        in float physics_localWaviness;

        in vec2 physics_localPosition;

        #include "/lib/modded/physicsMod/physicsModFragment.glsl"
    #endif

    uniform int isEyeInWater;

    uniform float nightVision;

    uniform sampler2D tex;

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
        uniform float near;

        uniform sampler2D depthtex1;
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

            #include "/lib/lighting/shdMapping.glsl"
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

    #include "/lib/lighting/complexShadingForward.glsl"

    void main(){
	    // Declare materials
	    dataPBR material;
        getPBR(material, blockId);
        
        // If water
        if(blockId == 11102){
            float waterNoise = WATER_BRIGHTNESS;

            #ifdef PHYSICS_OCEAN
                // Physics mod water normal calculation
                WavePixelData wave = physics_wavePixel(physics_localPosition, physics_localWaviness);

                // Underwater normal fix
                material.normal = !gl_FrontFacing ? -wave.normal : wave.normal;

                // Apply physics foam
                float physicsFoam = fastSqrt(wave.foam);
                material.albedo = min(vec4(1), material.albedo + physicsFoam);

                waterNoise *= physicsFoam;
            #elif defined WATER_NORMAL
                vec4 waterData = H2NWater(waterNoiseUv).xzyw;
                material.normal = fastNormalize(waterData.yxz * TBN[2].x + waterData.xyz * TBN[2].y + waterData.xzy * TBN[2].z);

                #ifdef WATER_NOISE
                    waterNoise *= squared(0.128 + waterData.w * 0.5);
                #endif
            #elif defined WATER_NOISE
                float waterData = getCellNoise(waterNoiseUv);

                waterNoise *= squared(0.128 + waterData * 0.5);
            #endif

            #if defined WATER_STYLIZE_ABSORPTION || defined WATER_FOAM
                // Water color and foam. Fast depth linearization by DrDesten
                float waterDepth = near / (1.0 - gl_FragCoord.z) - near / (1.0 - texelFetch(depthtex1, ivec2(gl_FragCoord.xy), 0).x);
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

        material.albedo.rgb = toLinear(material.albedo.rgb);

        // Write to HDR scene color
        sceneColOut = vec4(complexShadingForward(material), material.albedo.a);

        // Write buffer datas
        normalDataOut = material.normal;
        albedoDataOut = material.albedo.rgb;
        materialDataOut = vec3(material.metallic, material.smoothness, 0);
    }
#endif