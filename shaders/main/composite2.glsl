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
        flat out vec3 sRGBLightCol;
        flat out vec3 lightCol;

        noperspective out vec2 texCoord;

        #ifndef FORCE_DISABLE_WEATHER
            uniform float rainStrength;
        #endif

        #ifndef FORCE_DISABLE_DAY_CYCLE
            uniform float dayCycle;
            uniform float twilightPhase;
        #endif
    #endif

    void main(){
        #ifdef WORLD_LIGHT
            // Get buffer texture coordinates
            texCoord = gl_MultiTexCoord0.xy;

            sRGBLightCol = LIGHT_COLOR_DATA_BLOCK0;
            lightCol = toLinear(sRGBLightCol);
        #endif

        gl_Position = vec4(gl_Vertex.xy * 2.0 - 1.0, 0, 1);
    }
#endif

/// -------------------------------- /// Fragment Shader /// -------------------------------- ///

#ifdef FRAGMENT
    /* RENDERTARGETS: 0 */
    layout(location = 0) out vec3 volColOut; // colortex0

    #ifdef WORLD_LIGHT
        flat in vec3 sRGBLightCol;
        flat in vec3 lightCol;

        noperspective in vec2 texCoord;

        uniform int isEyeInWater;

        uniform float far;
        uniform float shdFade;
        uniform float borderFar;

        uniform float darkEffectFactor;
        uniform float darknessLightFactor;

        uniform vec3 fogColor;

        uniform vec3 cameraPosition;

        uniform mat4 gbufferProjectionInverse;
        uniform mat4 gbufferModelViewInverse;

        uniform sampler2D depthtex0;

        #if ANTI_ALIASING >= 2
            uniform float frameFract;
        #endif

        #ifndef FORCE_DISABLE_WEATHER
            uniform float rainStrength;
        #endif

        #ifndef FORCE_DISABLE_DAY_CYCLE
            uniform float dayCycle;
            uniform float dayCycleAdjust;
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

        #if defined VOLUMETRIC_LIGHTING && defined SHADOW_MAPPING
            uniform mat4 shadowProjection;
            uniform mat4 shadowModelView;
        #endif
    
        #include "/lib/lighting/shdDistort.glsl"
        #include "/lib/lighting/shdSampleTexel.glsl"

        #include "/lib/utility/noiseFunctions.glsl"
        #include "/lib/utility/projectionFunctions.glsl"
        
        #include "/lib/rayTracing/volumetricLight.glsl"
        
        #include "/lib/atmospherics/fogRender.glsl"
    #endif

    void main(){
        volColOut = vec3(0);

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

            // Get view distance
            float viewDot = lengthSquared(viewPos);
            float viewDotInvSqrt = inversesqrt(viewDot);
            float viewDist = viewDot * viewDotInvSqrt;

            // Get fog factor
            float fogFactor = getFogFactor(viewDist, eyePlayerPos.y * viewDotInvSqrt, feetPlayerPos.y + cameraPosition.y);

            // Border fog
            #ifdef BORDER_FOG
                float borderFog = getBorderFog(viewDist);
            #else
                float borderFog = 0.0;
            #endif

            bool isSky = depth == 1;

            float feetPlayerDot = lengthSquared(feetPlayerPos);
            float feetPlayerDotInvSqrt = inversesqrt(feetPlayerDot);
            float feetPlayerDist = feetPlayerDot * feetPlayerDotInvSqrt;

            vec3 nFeetPlayerPos = feetPlayerPos * feetPlayerDotInvSqrt;

            #if ANTI_ALIASING >= 2
                vec3 dither = fract(getRng3(screenTexelCoord & 255) + frameFract);
            #else
                vec3 dither = getRng3(screenTexelCoord & 255);
            #endif
            
            // Apply volumetric light
            volColOut = getVolumetricLight(nFeetPlayerPos, feetPlayerDist, fogFactor, borderFog, dither.x, isSky);
        #endif
    }
#endif