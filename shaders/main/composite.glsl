/*
================================ /// Super Duper Vanilla v1.3.3 /// ================================

    Developed by Eldeston, presented by FlameRender (TM) Studios.

    Copyright (C) 2020 Eldeston | FlameRender (TM) Studios License


    By downloading this content you have agreed to the license and its terms of use.

================================ /// Super Duper Vanilla v1.3.3 /// ================================
*/

/// Buffer features: Transparent complex shading and volumetric lighting

/// -------------------------------- /// Vertex Shader /// -------------------------------- ///

#ifdef VERTEX
    out vec2 texCoord;

    flat out vec3 skyCol;

    #ifdef WORLD_LIGHT
        flat out vec3 sRGBLightCol;
        flat out vec3 lightCol;
    #endif

    #ifndef FORCE_DISABLE_WEATHER
        uniform float rainStrength;
    #endif

    #ifndef FORCE_DISABLE_DAY_CYCLE
        uniform float dayCycle;
        uniform float zenithPhase;
    #endif

    #ifdef WORLD_VANILLA_FOG_COLOR
        uniform vec3 fogColor;
    #endif

    void main(){
        // Get buffer texture coordinates
        texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

        skyCol = toLinear(SKY_COL_DATA_BLOCK);

        #ifdef WORLD_LIGHT
            sRGBLightCol = LIGHT_COL_DATA_BLOCK;
            lightCol = toLinear(sRGBLightCol);
        #endif

        gl_Position = ftransform();
    }
#endif

/// -------------------------------- /// Fragment Shader /// -------------------------------- ///

#ifdef FRAGMENT
    in vec2 texCoord;

    flat in vec3 skyCol;

    #ifdef WORLD_LIGHT
        flat in vec3 sRGBLightCol;
        flat in vec3 lightCol;
    #endif

    uniform int isEyeInWater;

    uniform float far;

    uniform float blindness;
    uniform float nightVision;
    uniform float darknessFactor;
    uniform float darknessLightFactor;

    uniform float frameTimeCounter;

    uniform vec3 fogColor;

    uniform vec3 cameraPosition;

    uniform mat4 gbufferProjectionInverse;

    uniform mat4 gbufferModelViewInverse;

    uniform mat4 shadowModelView;

    uniform sampler2D gcolor;
    uniform sampler2D colortex3;
    uniform sampler2D colortex4;

    uniform sampler2D depthtex0;
    uniform sampler2D depthtex1;

    #ifndef FORCE_DISABLE_WEATHER
        uniform float rainStrength;
    #endif

    #ifndef FORCE_DISABLE_DAY_CYCLE
        uniform float dayCycle;
        uniform float zenithPhase;
    #endif

    #ifdef WORLD_SKYLIGHT
        const float eyeBrightFact = WORLD_SKYLIGHT;
    #else
        uniform ivec2 eyeBrightnessSmooth;
        
        float eyeBrightFact = eyeBrightnessSmooth.y * 0.00416667;
    #endif

    #ifdef WORLD_LIGHT
        uniform float shdFade;

        #if defined VOL_LIGHT && defined SHD_ENABLE
            uniform mat4 shadowProjection;

            #include "/lib/lighting/shdMapping.glsl"
            #include "/lib/lighting/shdDistort.glsl"
        #endif

        #include "/lib/rayTracing/volLight.glsl"
    #endif

    #include "/lib/utility/convertViewSpace.glsl"

    #include "/lib/utility/noiseFunctions.glsl"

    #include "/lib/atmospherics/skyRender.glsl"
    #include "/lib/atmospherics/fogRender.glsl"

    float getSpectral(in ivec2 iUv){
        ivec2 topRightCorner = iUv - 1;
        ivec2 bottomLeftCorner = iUv + 1;

        float sample0 = texelFetch(colortex3, topRightCorner, 0).z;
        float sample1 = texelFetch(colortex3, bottomLeftCorner, 0).z;
        float sample2 = texelFetch(colortex3, ivec2(topRightCorner.x, bottomLeftCorner.y), 0).z;
        float sample3 = texelFetch(colortex3, ivec2(bottomLeftCorner.x, topRightCorner.y), 0).z;

        float sumDepth = sample0 + sample1 + sample2 + sample3;

        return abs(sumDepth * 0.25 - texelFetch(colortex3, iUv, 0).z);
    }

    void main(){
        // Screen texel coordinates
        ivec2 screenTexelCoord = ivec2(gl_FragCoord.xy);
        // Get screen pos
        vec3 screenPos = vec3(texCoord, texelFetch(depthtex0, screenTexelCoord, 0).x);
        // Get view pos
        vec3 viewPos = toView(screenPos);
        // Get eye player pos
        vec3 eyePlayerPos = mat3(gbufferModelViewInverse) * viewPos;
        // Get feet player pos
        vec3 feetPlayerPos = eyePlayerPos + gbufferModelViewInverse[3].xyz;

        // Get scene color
        vec3 sceneCol = texelFetch(gcolor, screenTexelCoord, 0).rgb;

        #if ANTI_ALIASING >= 2
            vec3 dither = toRandPerFrame(getRand3(screenTexelCoord & 255), frameTimeCounter);
        #else
            vec3 dither = getRand3(screenTexelCoord & 255);
        #endif

        // If the object is a transparent render separate lighting
        if(texelFetch(depthtex1, screenTexelCoord, 0).x > screenPos.z){
            // Get view distance
            float viewDist = length(viewPos);

            // Get normalized eyePlayerPos
            vec3 nEyePlayerPos = eyePlayerPos / viewDist;

            // Get skyCol as our fogCol. Do basic sky render.
            vec3 fogCol = getSkyRender(nEyePlayerPos, false, false);
            // Fog and sky calculation
            sceneCol = getFogRender(sceneCol, fogCol, viewDist, nEyePlayerPos.y, eyePlayerPos.y + gbufferModelViewInverse[3].y + cameraPosition.y);
        }

        // Apply darkness pulsing effect
        sceneCol *= 1.0 - darknessLightFactor;

        // Apply spectral effect
        sceneCol += getSpectral(screenTexelCoord) * EMISSIVE_INTENSITY;

        #ifdef WORLD_LIGHT
            // Apply volumetric light
            sceneCol += getVolumetricLight(feetPlayerPos, screenPos.z, dither.x) * min(1.0, VOL_LIGHT_BRIGHTNESS + VOL_LIGHT_BRIGHTNESS * isEyeInWater) * shdFade;
        #endif

        // Clamp scene color to prevent negative/NaN values
        sceneCol = max(sceneCol, vec3(0));

    /* DRAWBUFFERS:0 */
        gl_FragData[0] = vec4(sceneCol, 1); // gcolor
    }
#endif