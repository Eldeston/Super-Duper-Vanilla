/*
================================ /// Super Duper Vanilla v1.3.9 /// ================================

    Developed by Eldeston, presented by FlameRender (C) Studios.

    Copyright (C) 2025 Eldeston | FlameRender (C) Studios License


    By downloading this content you have agreed to the license and its terms of use.

================================ /// Super Duper Vanilla v1.3.9 /// ================================
*/

/// Buffer features: Volumetric lighting

/// -------------------------------- /// Vertex Shader /// -------------------------------- ///

#ifdef VERTEX
    #ifdef WORLD_LIGHT
        noperspective out vec2 texCoord;
    #endif

    void main(){
        #ifdef WORLD_LIGHT
            // Get buffer texture coordinates
            texCoord = gl_MultiTexCoord0.xy;
        #endif

        gl_Position = vec4(gl_Vertex.xy * 2.0 - 1.0, 0, 1);
    }
#endif

/// -------------------------------- /// Fragment Shader /// -------------------------------- ///

#ifdef FRAGMENT
    /* RENDERTARGETS: 0 */
    layout(location = 0) out vec3 volColOut; // colortex0

    #ifdef WORLD_LIGHT
        noperspective in vec2 texCoord;

        uniform int isEyeInWater;
        uniform int frameCounter;
        
        uniform float borderFar;
        uniform float frameFract;

        uniform mat4 gbufferProjectionInverse;
        uniform mat4 gbufferModelViewInverse;

        uniform sampler2D depthtex0;


        #ifndef FORCE_DISABLE_WEATHER
            uniform float rainStrength;
        #endif

        #ifdef DISTANT_HORIZONS
            uniform mat4 dhProjectionInverse;

            uniform sampler2D dhDepthTex0;
        #endif

        #ifdef VOXY
            uniform mat4 vxProjInv;

            uniform sampler2D vxDepthTexOpaque;
        #endif

        #ifdef WORLD_CUSTOM_SKYLIGHT
            const float eyeBrightFact = WORLD_CUSTOM_SKYLIGHT;
        #else
            uniform float eyeSkylight;
            
            float eyeBrightFact = eyeSkylight;
        #endif

        #include "/lib/utility/projectionFunctions.glsl"
        
        #if defined VOLUMETRIC_LIGHTING && defined SHADOW_MAPPING
            uniform mat4 shadowProjection;
            uniform mat4 shadowModelView;

            #include "/lib/lighting/shdDistort.glsl"
            #include "/lib/lighting/shdSampleTexel.glsl"
        #endif

        #include "/lib/utility/noiseFunctions.glsl"
        
        #include "/lib/rayTracing/volumetricLight.glsl"
    #endif

    void main(){
        #ifdef WORLD_LIGHT
            if(VOLUMETRIC_LIGHTING_STRENGTH == 0 || isEyeInWater == 2) return;

            bool realSky = false;
            // Screen texel coordinates
            ivec2 screenTexelCoord = ivec2(gl_FragCoord.xy * 2.0);
            // Get screen space depth
            float depth = getDepth(depthtex0, screenTexelCoord, 0);

            // Distant Horizons and Voxy apparently uses a different depth texture
            #if defined DISTANT_HORIZONS
                realSky = depth == 1;
                if(realSky) depth = texelFetch(dhDepthTex0, screenTexelCoord, 0).x;
            #elif defined VOXY
                realSky = depth == 1;
                if(realSky) depth = texelFetch(vxDepthTexOpaque, screenTexelCoord, 0).x;
            #endif

            // Get screen pos
            vec3 screenPos = vec3(texCoord, depth);

            // Distant Horizons and Voxy apparently uses a different projection matrix
            #if defined DISTANT_HORIZONS
                vec3 viewPos = getViewPos(realSky ? dhProjectionInverse : gbufferProjectionInverse, screenPos);
            #elif defined VOXY
                vec3 viewPos = getViewPos(realSky ? vxProjInv : gbufferProjectionInverse, screenPos);
            #else
                vec3 viewPos = getViewPos(gbufferProjectionInverse, screenPos);
            #endif

            // Get eye player pos
            vec3 eyePlayerPos = mat3(gbufferModelViewInverse) * viewPos;
            // Get feet player pos
            vec3 feetPlayerPos = eyePlayerPos + gbufferModelViewInverse[3].xyz;

            bool isSky = depth == 1;

            float feetPlayerDot = lengthSquared(feetPlayerPos);
            float feetPlayerDotInvSqrt = inversesqrt(feetPlayerDot);
            float feetPlayerDist = feetPlayerDot * feetPlayerDotInvSqrt;

            vec3 nFeetPlayerPos = feetPlayerPos * feetPlayerDotInvSqrt;
            
            // Apply volumetric light
            volColOut = getVolumetricLight(nFeetPlayerPos, feetPlayerDist, isSky);
        #else
            volColOut = vec3(0);
        #endif
    }
#endif