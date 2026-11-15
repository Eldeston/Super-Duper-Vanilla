/*
================================ /// Super Duper Vanilla v1.3.9 /// ================================

    Developed by Eldeston, presented by FlameRender (C) Studios.

    Copyright (C) 2025 Eldeston | FlameRender (C) Studios License


    By downloading this content you have agreed to the license and its terms of use.

================================ /// Super Duper Vanilla v1.3.9 /// ================================
*/

/// Buffer features: Upsampling composite stage

/// -------------------------------- /// Vertex Shader /// -------------------------------- ///

#ifdef VERTEX
    #ifdef WORLD_LIGHT
        flat out vec3 lightCol;

        noperspective out vec2 texCoord;

        uniform int isEyeInWater;
        
        uniform float shdFade;

        #ifndef FORCE_DISABLE_WEATHER
            uniform float rainStrength;
        #endif

        #if !defined VOLUMETRIC_LIGHTING || !defined SHADOW_MAPPING
            uniform vec3 fogColor;
        #endif

        #ifndef FORCE_DISABLE_DAY_CYCLE
            uniform float dayCycle;
            uniform float twilightPhase;
        #endif

        #ifdef WORLD_CUSTOM_SKYLIGHT
            const float eyeBrightFact = WORLD_CUSTOM_SKYLIGHT;
        #else
            uniform float eyeSkylight;
            
            float eyeBrightFact = eyeSkylight;
        #endif
    #endif

    void main(){
        #ifdef WORLD_LIGHT
            // Get buffer texture coordinates
            texCoord = gl_MultiTexCoord0.xy;

            vec3 sRGBLightCol = LIGHT_COLOR_DATA_BLOCK0;

            #if defined VOLUMETRIC_LIGHTING && defined SHADOW_MAPPING
                lightCol = toLinear(sRGBLightCol) * min(1.0, VOLUMETRIC_LIGHTING_STRENGTH + VOLUMETRIC_LIGHTING_STRENGTH * isEyeInWater) * shdFade;
            #else
                lightCol = toLinear(sRGBLightCol) * squared(eyeBrightFact) * VOLUMETRIC_LIGHTING_STRENGTH;
                if(isEyeInWater == 1) lightCol = toLinear(sRGBLightCol) * toLinear(fogColor) * min(1.0, VOLUMETRIC_LIGHTING_STRENGTH * 2.0);
            #endif
        #endif

        gl_Position = vec4(gl_Vertex.xy * 2.0 - 1.0, 0, 1);
    }
#endif

/// -------------------------------- /// Fragment Shader /// -------------------------------- ///

#ifdef FRAGMENT
    /* RENDERTARGETS: 4 */
    layout(location = 0) out vec3 sceneColOut; // colortex4

    uniform sampler2D colortex4;

    #ifdef WORLD_LIGHT
        flat in vec3 lightCol;

        noperspective in vec2 texCoord;

        uniform int isEyeInWater;
        
        uniform float borderFar;

        uniform vec3 cameraPosition;

        uniform mat4 gbufferProjectionInverse;
        uniform mat4 gbufferModelViewInverse;

        uniform sampler2D colortex0;
        uniform sampler2D depthtex0;

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

        #include "/lib/utility/projectionFunctions.glsl"
        
        #include "/lib/atmospherics/fogRender.glsl"
    #endif

    void main(){
        // Screen texel coordinates
        ivec2 screenTexelCoord = ivec2(gl_FragCoord.xy);

        // Get scene color
        sceneColOut = texelFetch(colortex4, screenTexelCoord, 0).rgb;

        #ifdef WORLD_LIGHT
            if(VOLUMETRIC_LIGHTING_STRENGTH == 0 || isEyeInWater == 2) return;

            bool realSky = false;
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

            // Get fog factor
            float fogFactor = getFogFactor(feetPlayerDist, nFeetPlayerPos.y, feetPlayerPos.y + cameraPosition.y);

            // Border fog
            #ifdef BORDER_FOG
                float borderFog = getBorderFog(feetPlayerDist);
            #else
                float borderFog = 0.0;
            #endif

            float totalFogDensity = FOG_TOTAL_DENSITY;

            #ifdef FORCE_DISABLE_WEATHER
                if(isEyeInWater != 0) totalFogDensity *= TAU;
            #else
                totalFogDensity *= isEyeInWater == 0 ? (rainStrength * PI + 1.0) : TAU;
            #endif

            float volumetricFogDensity = 1.0 - exp2(-feetPlayerDist * totalFogDensity);
            volumetricFogDensity = (volumetricFogDensity - fogFactor) * VOLUMETRIC_LIGHTING_STRENGTH + fogFactor;

            // Border fog
            #ifdef BORDER_FOG
                volumetricFogDensity = (volumetricFogDensity - 1.0) * borderFog + 1.0;
            #endif

            // Apply half res volumetric light
            sceneColOut += texelFetch(colortex0, ivec2(gl_FragCoord.xy * 0.5), 0).rgb * lightCol * volumetricFogDensity;
        #endif

        // Clamp scene color to prevent NaNs during post processing
        sceneColOut = max(sceneColOut, vec3(0));
    }
#endif