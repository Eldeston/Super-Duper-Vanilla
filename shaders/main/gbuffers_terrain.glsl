/*
================================ /// Super Duper Vanilla v1.3.3 /// ================================

    Developed by Eldeston, presented by FlameRender (TM) Studios.

    Copyright (C) 2020 Eldeston | FlameRender (TM) Studios License


    By downloading this content you have agreed to the license and its terms of use.

================================ /// Super Duper Vanilla v1.3.3 /// ================================
*/

/// Buffer features: TAA jittering, complex shading, animation, lava noise, PBR, and world curvature

/// -------------------------------- /// Vertex Shader /// -------------------------------- ///

#ifdef VERTEX
    flat out mat3 TBN;
    
    flat out int blockId;

    flat out vec3 vertexColor;

    out float vertexAO;

    out vec2 lmCoord;
    out vec2 texCoord;

    #if defined AUTO_GEN_NORM || defined PARALLAX_OCCLUSION
        flat out vec2 vTexCoordScale;
        flat out vec2 vTexCoordPos;
        out vec2 vTexCoord;
    #endif

    out vec3 worldPos;

    out vec4 vertexPos;

    // View matrix uniforms
    uniform mat4 gbufferModelView;
    uniform mat4 gbufferModelViewInverse;

    // Position uniforms
    uniform vec3 cameraPosition;

    #if ANTI_ALIASING == 2
        /* Screen resolutions */
        uniform float viewWidth;
        uniform float viewHeight;

        #include "/lib/utility/taaJitter.glsl"
    #endif

    attribute vec3 mc_Entity;

    attribute vec4 at_tangent;

    #if defined AUTO_GEN_NORM || defined PARALLAX_OCCLUSION || defined TERRAIN_ANIMATION
        attribute vec2 mc_midTexCoord;
    #endif

    #ifdef TERRAIN_ANIMATION
        #if TIMELAPSE_MODE == 2
            uniform float animationFrameTime;

            float newFrameTimeCounter = animationFrameTime;
        #else
            uniform float frameTimeCounter;

            float newFrameTimeCounter = frameTimeCounter;
        #endif

        attribute vec3 at_midBlock;

        #include "/lib/vertex/terrainWave.glsl"
    #endif

    void main(){
        // Get block id
        blockId = int(mc_Entity.x);
        // Get vertex AO
        vertexAO = gl_Color.a;
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
            vec2 midTexCoord = (gl_TextureMatrix[0] * vec4(mc_midTexCoord, 0, 0)).xy;
            vec2 texMinMidTexCoord = texCoord - midTexCoord;

            vTexCoordScale = abs(texMinMidTexCoord) * 2.0;
            vTexCoordPos = min(texCoord, midTexCoord - texMinMidTexCoord);
            vTexCoord = sign(texMinMidTexCoord) * 0.5 + 0.5;
        #endif

        #if defined TERRAIN_ANIMATION || defined WORLD_CURVATURE
            #ifdef TERRAIN_ANIMATION
                // Apply terrain wave animation
                vertexPos.xyz = getTerrainWave(vertexPos.xyz, worldPos, at_midBlock, mc_Entity.x, lmCoord.y);
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
    flat in mat3 TBN;

    flat in int blockId;

    flat in vec3 vertexColor;

    in float vertexAO;

    in vec2 lmCoord;
    in vec2 texCoord;

    #if defined AUTO_GEN_NORM || defined PARALLAX_OCCLUSION
        flat in vec2 vTexCoordScale;
        flat in vec2 vTexCoordPos;
        in vec2 vTexCoord;
    #endif

    in vec3 worldPos;

    in vec4 vertexPos;

    // Enable full vanilla AO
    const float ambientOcclusionLevel = 1.0;

    // Get albedo texture
    uniform sampler2D tex;

    #ifdef WORLD_LIGHT
        // Shadow view matrix uniforms
        uniform mat4 shadowModelView;

        #ifdef SHD_ENABLE
            // Shadow projection matrix uniforms
            uniform mat4 shadowProjection;
        #endif
    #endif

    // Get is eye in water
    uniform int isEyeInWater;

    // Get night vision
    uniform float nightVision;

    #ifndef FORCE_DISABLE_WEATHER
        // Get rain strength
        uniform float rainStrength;
    #endif

    #if TIMELAPSE_MODE != 0
        uniform float animationFrameTime;

        float newFrameTimeCounter = animationFrameTime;
    #else
        uniform float frameTimeCounter;
        
        float newFrameTimeCounter = frameTimeCounter;
    #endif

    // Texture coordinate derivatives
    vec2 dcdx = dFdx(texCoord);
    vec2 dcdy = dFdy(texCoord);

    #include "/lib/universalVars.glsl"

    #include "/lib/utility/noiseFunctions.glsl"

    #include "/lib/lighting/shdMapping.glsl"
    #include "/lib/lighting/shdDistort.glsl"
    #include "/lib/lighting/GGX.glsl"

    #include "/lib/surface/lava.glsl"

    #include "/lib/PBR/structPBR.glsl"

    #if PBR_MODE <= 1
        #include "/lib/PBR/defaultPBR.glsl"
    #else
        #include "/lib/PBR/labPBR.glsl"
    #endif

    #if defined ENVIRO_PBR && !defined FORCE_DISABLE_WEATHER
        #include "/lib/PBR/enviroPBR.glsl"
    #endif

    #include "/lib/lighting/complexShadingForward.glsl"

    void main(){
	    // Declare materials
	    structPBR material;
        getPBR(material, blockId);

        if(blockId == 10016){
            #ifdef LAVA_NOISE
                vec2 lavaUv = (worldPos.yz * TBN[2].x + worldPos.xz * TBN[2].y + worldPos.xy * TBN[2].z) / LAVA_TILE_SIZE;
                float lavaNoise = max(getLavaNoise(lavaUv), sumOf(material.albedo.rgb) * 0.33333333);
                material.albedo.rgb = floor(material.albedo.rgb * saturate((lavaNoise - 0.33333333) * 3.0) * LAVA_BRIGHTNESS * 32.0) * 0.03125;
            #else
                material.albedo.rgb = material.albedo.rgb * LAVA_BRIGHTNESS;
            #endif
        }

        material.albedo.rgb = toLinear(material.albedo.rgb);

        #if defined ENVIRO_PBR && !defined FORCE_DISABLE_WEATHER
            if(blockId != 10016) enviroPBR(material);
        #endif

        vec4 sceneCol = complexShadingGbuffers(material);

    /* DRAWBUFFERS:0123 */
        gl_FragData[0] = sceneCol; // gcolor
        gl_FragData[1] = vec4(material.normal, 1); // colortex1
        gl_FragData[2] = vec4(material.albedo.rgb, 1); // colortex2
        gl_FragData[3] = vec4(material.metallic, material.smoothness, 0, 1); // colortex3
    }
#endif