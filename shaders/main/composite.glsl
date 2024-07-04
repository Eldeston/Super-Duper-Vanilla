/*
================================ /// Super Duper Vanilla v1.3.5 /// ================================

    Developed by Eldeston, presented by FlameRender (C) Studios.

    Copyright (C) 2023 Eldeston | FlameRender (C) Studios License


    By downloading this content you have agreed to the license and its terms of use.

================================ /// Super Duper Vanilla v1.3.5 /// ================================
*/

/// Buffer features: Transparent complex shading and volumetric lighting

/// -------------------------------- /// Vertex Shader /// -------------------------------- ///

#ifdef VERTEX
    flat out vec3 skyCol;

    noperspective out vec2 texCoord;

    #ifdef WORLD_LIGHT
        flat out vec3 sRGBLightCol;
        flat out vec3 lightCol;

        #ifndef FORCE_DISABLE_DAY_CYCLE
            flat out vec3 sRGBSunCol;
            flat out vec3 sunCol;
            flat out vec3 sRGBMoonCol;
            flat out vec3 moonCol;
        #endif
    #endif

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

    void main(){
        // Get buffer texture coordinates
        texCoord = gl_MultiTexCoord0.xy;

        skyCol = toLinear(SKY_COLOR_DATA_BLOCK);

        #ifdef WORLD_LIGHT
            #ifdef FORCE_DISABLE_DAY_CYCLE
                sRGBLightCol = LIGHT_COLOR_DATA_BLOCK0;
                lightCol = toLinear(sRGBLightCol);
            #else
                sRGBSunCol = SUN_COL_DATA_BLOCK;
                sunCol = toLinear(sRGBSunCol);
                sRGBMoonCol = MOON_COL_DATA_BLOCK;
                moonCol = toLinear(sRGBMoonCol);

                sRGBLightCol = LIGHT_COLOR_DATA_BLOCK1(sRGBSunCol, sRGBMoonCol);
                lightCol = toLinear(sRGBLightCol);
            #endif
        #endif

        gl_Position = vec4(gl_Vertex.xy * 2.0 - 1.0, 0, 1);
    }
#endif

/// -------------------------------- /// Fragment Shader /// -------------------------------- ///

#ifdef FRAGMENT
    /* RENDERTARGETS: 0 */
    layout(location = 0) out vec3 sceneColOut; // gcolor

    flat in vec3 skyCol;

    #ifdef WORLD_LIGHT
        flat in vec3 sRGBLightCol;
        flat in vec3 lightCol;

        #ifndef FORCE_DISABLE_DAY_CYCLE
            flat in vec3 sRGBSunCol;
            flat in vec3 sunCol;
            flat in vec3 sRGBMoonCol;
            flat in vec3 moonCol;
        #endif
    #endif

    noperspective in vec2 texCoord;

    uniform int isEyeInWater;

    uniform float borderFar;

    uniform float blindness;
    uniform float nightVision;
    uniform float darknessFactor;
    uniform float darknessLightFactor;

    uniform float fragmentFrameTime;

    uniform vec3 fogColor;

    uniform vec3 cameraPosition;

    uniform mat4 gbufferProjection;
    uniform mat4 gbufferProjectionInverse;

    uniform mat4 gbufferModelView;
    uniform mat4 gbufferModelViewInverse;

    uniform mat4 shadowModelView;

    uniform sampler2D gcolor;
    uniform sampler2D colortex1;
    uniform sampler2D colortex2;
    uniform sampler2D colortex3;

    uniform sampler2D depthtex0;
    uniform sampler2D depthtex1;

    #ifdef IS_IRIS
        uniform float lightningFlash;
    #endif

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

    #if defined STORY_MODE_CLOUDS && !defined FORCE_DISABLE_CLOUDS
        uniform sampler2D colortex4;
    #endif

    #ifdef DISTANT_HORIZONS
        uniform mat4 dhProjection;
        uniform mat4 dhProjectionInverse;

        uniform sampler2D dhDepthTex0;
    #endif

    #ifdef WORLD_CUSTOM_SKYLIGHT
        const float eyeBrightFact = WORLD_CUSTOM_SKYLIGHT;
    #else
        uniform float eyeSkylight;
        
        float eyeBrightFact = eyeSkylight;
    #endif

    #include "/lib/utility/projectionFunctions.glsl"

    #ifdef PREVIOUS_FRAME
        uniform vec3 previousCameraPosition;

        uniform mat4 gbufferPreviousModelView;
        uniform mat4 gbufferPreviousProjection;

        uniform sampler2D colortex5;

        #include "/lib/utility/prevProjectionFunctions.glsl"
    #endif

    #ifdef WORLD_LIGHT
        uniform float shdFade;

        #if defined VOLUMETRIC_LIGHTING && defined SHADOW_MAPPING
            uniform mat4 shadowProjection;

            #include "/lib/lighting/shdMapping.glsl"
        #endif

        #include "/lib/rayTracing/volLight.glsl"
    #endif

    #include "/lib/utility/noiseFunctions.glsl"

    #include "/lib/atmospherics/skyRender.glsl"
    #include "/lib/atmospherics/fogRender.glsl"

    #include "/lib/rayTracing/rayTracer.glsl"

    #include "/lib/lighting/complexShadingDeferred.glsl"

    #ifndef IS_IRIS
        bool isSpectralMask(in ivec2 iUv){
            return texelFetch(colortex3, iUv, 0).z == 1;
        }

        float getSpectral(in ivec2 iUv){
            ivec2 topRightCorner = iUv - 1;
            ivec2 bottomLeftCorner = iUv + 1;

            bool sample0 = isSpectralMask(topRightCorner);
            bool sample1 = isSpectralMask(bottomLeftCorner);

            if(sample0 && !sample1 || sample1 && !sample0) return EMISSIVE_INTENSITY;

            bool sample2 = isSpectralMask(ivec2(topRightCorner.x, bottomLeftCorner.y));
            bool sample3 = isSpectralMask(ivec2(bottomLeftCorner.x, topRightCorner.y));

            if(sample2 && !sample3 || sample3 && !sample2) return EMISSIVE_INTENSITY;

            return 0.0;
        }
    #endif

    void main(){
        // Screen texel coordinates
        ivec2 screenTexelCoord = ivec2(gl_FragCoord.xy);

        // Distant Horizons apparently uses a different depth texture
        #ifdef DISTANT_HORIZONS
            float depth = texelFetch(depthtex0, screenTexelCoord, 0).x;
            bool realSky = depth == 1;
            if(realSky) depth = texelFetch(dhDepthTex0, screenTexelCoord, 0).x;
        #else
            float depth = texelFetch(depthtex0, screenTexelCoord, 0).x;
        #endif

        // Get screen pos
        vec3 screenPos = vec3(texCoord, depth);
        
        // Distant Horizons apparently uses a different projection matrix
        #ifdef DISTANT_HORIZONS
            vec3 viewPos = getViewPos(realSky ? dhProjectionInverse : gbufferProjectionInverse, screenPos);
        #else
            vec3 viewPos = getViewPos(gbufferProjectionInverse, screenPos);
        #endif

        // Get eye player pos
        vec3 eyePlayerPos = mat3(gbufferModelViewInverse) * viewPos;
        // Get feet player pos
        vec3 feetPlayerPos = eyePlayerPos + gbufferModelViewInverse[3].xyz;

        // Get scene color
        sceneColOut = texelFetch(gcolor, screenTexelCoord, 0).rgb;

        #if ANTI_ALIASING >= 2
            vec3 dither = fract(getRng3(screenTexelCoord & 255) + frameFract);
        #else
            vec3 dither = getRng3(screenTexelCoord & 255);
        #endif

        // If the object is a transparent render separate lighting
        if(texelFetch(depthtex1, screenTexelCoord, 0).x > screenPos.z){
            // Get view distance
            float viewDot = lengthSquared(viewPos);
            float viewDotInvSqrt = inversesqrt(viewDot);
            float viewDist = viewDot * viewDotInvSqrt;

            // Get normalized eyePlayerPos
            vec3 nEyePlayerPos = eyePlayerPos * viewDotInvSqrt;

            // Declare and get materials
            vec2 matRaw0 = texelFetch(colortex3, screenTexelCoord, 0).xy;
            vec3 albedo = texelFetch(colortex2, screenTexelCoord, 0).rgb;
            vec3 normal = texelFetch(colortex1, screenTexelCoord, 0).xyz;

            // Apply deffered shading
            sceneColOut = complexShadingDeferred(sceneColOut, screenPos, viewPos, mat3(gbufferModelView) * normal, albedo, viewDotInvSqrt, matRaw0.x, matRaw0.y, dither);

            // Get basic sky fog color
            vec3 fogSkyCol = getSkyFogRender(nEyePlayerPos);
            // Do basic sky render and use it as fog color
            sceneColOut = getFogRender(sceneColOut, fogSkyCol, viewDist, nEyePlayerPos.y, feetPlayerPos.y + cameraPosition.y);
        }

        // Apply darkness pulsing effect
        sceneColOut *= 1.0 - darknessLightFactor;

        #ifndef IS_IRIS
            // Apply spectral effect
            sceneColOut += getSpectral(screenTexelCoord);
        #endif

        #ifdef WORLD_LIGHT
            // Apply volumetric light
            if(VOLUMETRIC_LIGHTING_STRENGTH != 0 && isEyeInWater != 2)
                sceneColOut += getVolumetricLight(feetPlayerPos, screenPos.z, dither.x);
        #endif

        // Clamp scene color to prevent NaNs during post processing
        sceneColOut = max(sceneColOut, vec3(0));
    }
#endif