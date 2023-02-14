/*
================================ /// Super Duper Vanilla v1.3.3 /// ================================

    Developed by Eldeston, presented by FlameRender (TM) Studios.

    Copyright (C) 2020 Eldeston | FlameRender (TM) Studios License


    By downloading this content you have agreed to the license and its terms of use.

================================ /// Super Duper Vanilla v1.3.3 /// ================================
*/

/// Buffer features: TAA jittering, complex shading, animation, water noise, PBR, and world curvature

/// -------------------------------- /// Vertex Shader /// -------------------------------- ///

#ifdef VERTEX
    flat out int blockId;

    flat out vec3 vertexColor;

    flat out mat3 TBN;

    out vec2 lmCoord;
    out vec2 texCoord;

    out vec3 worldPos;

    out vec4 vertexPos;

    #if defined AUTO_GEN_NORM || defined PARALLAX_OCCLUSION
        flat out vec2 vTexCoordScale;
        flat out vec2 vTexCoordPos;

        out vec2 vTexCoord;
    #endif

    uniform vec3 cameraPosition;

    uniform mat4 gbufferModelView;
    uniform mat4 gbufferModelViewInverse;
    
    #if ANTI_ALIASING == 2
        uniform float viewWidth;
        uniform float viewHeight;

        #include "/lib/utility/taaJitter.glsl"
    #endif

    #ifdef WATER_ANIMATION
        #if TIMELAPSE_MODE == 2
            uniform float animationFrameTime;

            float newFrameTimeCounter = animationFrameTime;
        #else
            uniform float frameTimeCounter;

            float newFrameTimeCounter = frameTimeCounter;
        #endif

        #include "/lib/vertex/waterWave.glsl"
    #endif

    attribute vec3 mc_Entity;

    attribute vec4 at_tangent;

    #if defined AUTO_GEN_NORM || defined PARALLAX_OCCLUSION
        attribute vec2 mc_midTexCoord;
    #endif

    void main(){
        // Get block id
        blockId = int(mc_Entity.x);
        // Get buffer texture coordinates
        texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
        // Get vertex color
        vertexColor = gl_Color.rgb;

        // Get vertex tangent
        vec3 vertexTangent = fastNormalize(at_tangent.xyz);
        // Get vertex normal
        vec3 vertexNormal = fastNormalize(gl_Normal);

        // Get vertex position (feet player pos)
        vertexPos = gbufferModelViewInverse * (gl_ModelViewMatrix * gl_Vertex);
        // Get world position
        worldPos = vertexPos.xyz + cameraPosition;

        // Calculate TBN matrix
	    TBN = mat3(gbufferModelViewInverse) * (gl_NormalMatrix * mat3(vertexTangent, cross(vertexTangent, vertexNormal), vertexNormal));

        // Lightmap fix for mods
        #ifdef WORLD_SKYLIGHT
            lmCoord = vec2(saturate(gl_MultiTexCoord1.x * 0.00416667), WORLD_SKYLIGHT);
        #else
            lmCoord = saturate(gl_MultiTexCoord1.xy * 0.00416667);
        #endif

        #if defined AUTO_GEN_NORM || defined PARALLAX_OCCLUSION
            vec2 midCoord = (gl_TextureMatrix[0] * vec4(mc_midTexCoord, 0, 0)).xy;
            vec2 texMinMidCoord = texCoord - midCoord;

            vTexCoordScale = abs(texMinMidCoord) * 2.0;
            vTexCoordPos = min(texCoord, midCoord - texMinMidCoord);
            vTexCoord = sign(texMinMidCoord) * 0.5 + 0.5;
        #endif

        #if defined WATER_ANIMATION || defined WORLD_CURVATURE
            #ifdef WATER_ANIMATION
                // Apply water wave animation
                if(mc_Entity.x == 20502) vertexPos.y = getWaterWave(worldPos.xz, vertexPos.y);
            #endif

            #ifdef WORLD_CURVATURE
                // Apply curvature distortion
                vertexPos.y -= dot(vertexPos.xz, vertexPos.xz) / WORLD_CURVATURE_SIZE;
            #endif

            // Convert to clip pos and output as position
            gl_Position = gl_ProjectionMatrix * (gbufferModelView * vertexPos);
        #else
            gl_Position = ftransform();
        #endif

        #if ANTI_ALIASING == 2
            gl_Position.xy += jitterPos(gl_Position.w);
        #endif
    }
#endif

/// -------------------------------- /// Fragment Shader /// -------------------------------- ///

#ifdef FRAGMENT
    flat in int blockId;

    flat in vec3 vertexColor;

    flat in mat3 TBN;

    in vec2 lmCoord;
    in vec2 texCoord;

    in vec3 worldPos;

    in vec4 vertexPos;

    #if defined AUTO_GEN_NORM || defined PARALLAX_OCCLUSION
        flat in vec2 vTexCoordScale;
        flat in vec2 vTexCoordPos;

        in vec2 vTexCoord;
    #endif

    uniform int isEyeInWater;

    uniform float nightVision;
    uniform float lightningFlash;

    uniform sampler2D tex;

    // Texture coordinate derivatives
    vec2 dcdx = dFdx(texCoord);
    vec2 dcdy = dFdy(texCoord);

    #ifndef FORCE_DISABLE_WEATHER
        uniform float rainStrength;
    #endif

    #if defined WATER_STYLIZE_ABSORPTION || defined WATER_FOAM
        uniform mat4 gbufferProjectionInverse;

        uniform sampler2D depthtex1;

        #include "/lib/utility/convertViewSpace.glsl"
    #endif

    #if (defined SHD_FILTER && ANTI_ALIASING >= 2) || TIMELAPSE_MODE == 0
        uniform float frameTimeCounter;
    #endif

    #ifndef FORCE_DISABLE_DAY_CYCLE
        uniform float dayCycle;
        uniform float twilightPhase;
    #endif

    #ifdef WORLD_VANILLA_FOG_COLOR
        uniform vec3 fogColor;
    #endif

    #ifdef WORLD_SKYLIGHT
        const float eyeBrightFact = WORLD_SKYLIGHT;
    #else
        uniform ivec2 eyeBrightnessSmooth;
        
        float eyeBrightFact = eyeBrightnessSmooth.y * 0.00416667;
    #endif

    #if TIMELAPSE_MODE != 0
        uniform float animationFrameTime;

        float newFrameTimeCounter = animationFrameTime;
    #else
        float newFrameTimeCounter = frameTimeCounter;
    #endif

    #ifdef WORLD_LIGHT
        uniform float shdFade;

        uniform mat4 shadowModelView;

        #ifdef SHD_ENABLE
            uniform mat4 shadowProjection;

            #include "/lib/lighting/shdMapping.glsl"
            #include "/lib/lighting/shdDistort.glsl"
        #endif

        #include "/lib/lighting/GGX.glsl"
    #endif

    #include "/lib/PBR/structPBR.glsl"

    #if PBR_MODE <= 1
        #include "/lib/PBR/defaultPBR.glsl"
    #else
        #include "/lib/PBR/labPBR.glsl"
    #endif

    #include "/lib/utility/noiseFunctions.glsl"

    #if defined ENVIRO_PBR && !defined FORCE_DISABLE_WEATHER
        #include "/lib/PBR/enviroPBR.glsl"
    #endif

    #include "/lib/surface/water.glsl"

    #include "/lib/lighting/complexShadingForward.glsl"

    void main(){
	    // Declare materials
	    structPBR material;
        getPBR(material, blockId);
        
        // If water
        if(blockId == 20502){
            float waterNoise = WATER_BRIGHTNESS;

            #ifdef WATER_NORM
                vec4 waterData = H2NWater(worldPos.xz / WATER_TILE_SIZE);
                material.normal = TBN * waterData.xyz;

                #ifdef WATER_NOISE
                    waterNoise *= squared(0.128 + waterData.w);
                #endif
            #elif WATER_NOISE
                float waterData = getCellNoise(worldPos.xz / WATER_TILE_SIZE);

                waterNoise *= squared(0.128 + waterData);
            #endif

            #if defined WATER_STYLIZE_ABSORPTION || defined WATER_FOAM
                // Water color and foam 
                float waterDepth = toView(texelFetch(depthtex1, ivec2(gl_FragCoord.xy), 0).x) - toView(gl_FragCoord.z);
            #endif

            #ifdef WATER_STYLIZE_ABSORPTION
                if(isEyeInWater == 0){
                        float depthBrightness = exp2(waterDepth * 0.25);
                        material.albedo.rgb = material.albedo.rgb * (waterNoise * (1.0 - depthBrightness) + depthBrightness);
                        material.albedo.a = fastSqrt(material.albedo.a) * (1.0 - depthBrightness);
                }else material.albedo.rgb *= waterNoise;
            #else
                material.albedo.rgb *= waterNoise;
            #endif

            #ifdef WATER_FOAM
                material.albedo = min(vec4(1), material.albedo + exp2((waterDepth + 0.0625) * 8.0));
            #endif
        }

        material.albedo.rgb = toLinear(material.albedo.rgb);

        #if defined ENVIRO_PBR && !defined FORCE_DISABLE_WEATHER
            if(blockId != 20502) enviroPBR(material);
        #endif

        vec4 sceneCol = complexShadingGbuffers(material);

    /* DRAWBUFFERS:0123 */
        gl_FragData[0] = sceneCol; // gcolor
        gl_FragData[1] = vec4(material.normal, 1); // colortex1
        gl_FragData[2] = vec4(material.albedo.rgb, 1); // colortex2
        gl_FragData[3] = vec4(material.metallic, material.smoothness, 0, 1); // colortex3
    }
#endif