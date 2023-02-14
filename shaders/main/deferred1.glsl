/*
================================ /// Super Duper Vanilla v1.3.3 /// ================================

    Developed by Eldeston, presented by FlameRender (TM) Studios.

    Copyright (C) 2020 Eldeston | FlameRender (TM) Studios License


    By downloading this content you have agreed to the license and its terms of use.

================================ /// Super Duper Vanilla v1.3.3 /// ================================
*/

/// Buffer features: Solid complex shading

/// -------------------------------- /// Vertex Shader /// -------------------------------- ///

#ifdef VERTEX
    out vec2 texCoord;

    flat out vec3 skyCol;

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
        texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

        skyCol = toLinear(SKY_COL_DATA_BLOCK);

        #ifdef WORLD_LIGHT
            #ifdef FORCE_DISABLE_DAY_CYCLE
                sRGBLightCol = LIGHT_COL_DATA_BLOCK0;
                lightCol = toLinear(sRGBLightCol);
            #else
                sRGBSunCol = SUN_COL_DATA_BLOCK;
                sunCol = toLinear(sRGBSunCol);
                sRGBMoonCol = MOON_COL_DATA_BLOCK;
                moonCol = toLinear(sRGBMoonCol);
                sRGBLightCol = LIGHT_COL_DATA_BLOCK1(sRGBSunCol, sRGBMoonCol);
                lightCol = toLinear(sRGBLightCol);
            #endif
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

        #ifndef FORCE_DISABLE_DAY_CYCLE
            flat in vec3 sRGBSunCol;
            flat in vec3 sunCol;
            flat in vec3 sRGBMoonCol;
            flat in vec3 moonCol;
        #endif
    #endif
    
    // Sky silhoutte fix
    const vec4 gcolorClearColor = vec4(0, 0, 0, 1);

    uniform int isEyeInWater;

    uniform float far;

    uniform float blindness;
    uniform float nightVision;
    uniform float lightningFlash;
    uniform float darknessFactor;
    uniform float darknessLightFactor;

    uniform float frameTimeCounter;

    uniform float viewWidth;
    uniform float viewHeight;

    uniform vec3 fogColor;

    uniform vec3 cameraPosition;

    uniform mat4 gbufferProjectionInverse;

    uniform mat4 gbufferModelViewInverse;

    uniform mat4 shadowModelView;

    uniform sampler2D gcolor;
    uniform sampler2D colortex2;
    
    uniform sampler2D depthtex0;

    #ifdef WORLD_LIGHT
        uniform float shdFade;
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

    #ifdef WORLD_SKYLIGHT
        const float eyeBrightFact = WORLD_SKYLIGHT;
    #else
        uniform float eyeSkylight;
        
        float eyeBrightFact = eyeSkylight;
    #endif

    #ifdef SSAO
        float getSSAOBoxBlur(in ivec2 screenTexelCoord){
            ivec2 topRightCorner = screenTexelCoord + 1;
            ivec2 bottomLeftCorner = screenTexelCoord - 1;

            float sample0 = texelFetch(colortex2, topRightCorner, 0).a;
            float sample1 = texelFetch(colortex2, bottomLeftCorner, 0).a;
            float sample2 = texelFetch(colortex2, ivec2(topRightCorner.x, bottomLeftCorner.y), 0).a;
            float sample3 = texelFetch(colortex2, ivec2(bottomLeftCorner.x, topRightCorner.y), 0).a;

            return sample0 + sample1 + sample2 + sample3;
        }
    #endif

    #if ANTI_ALIASING == 2
        #include "/lib/utility/taaJitter.glsl"
    #endif

    #include "/lib/utility/convertViewSpace.glsl"

    #if OUTLINES != 0
        #include "/lib/post/outline.glsl"
    #endif

    #include "/lib/utility/noiseFunctions.glsl"

    #include "/lib/atmospherics/skyRender.glsl"
    #include "/lib/atmospherics/fogRender.glsl"

    void main(){
        // Screen texel coordinates
        ivec2 screenTexelCoord = ivec2(gl_FragCoord.xy);
        // Get screen pos
        vec3 screenPos = vec3(texCoord, texelFetch(depthtex0, screenTexelCoord, 0).x);
        
        // Get sky mask
        bool skyMask = screenPos.z == 1;

        // Jitter the sky only
        #if ANTI_ALIASING == 2
            if(skyMask) screenPos.xy += jitterPos(-0.5);
        #endif

        // Get view pos
        vec3 viewPos = toView(screenPos);
        // Get eye player pos
        vec3 eyePlayerPos = mat3(gbufferModelViewInverse) * viewPos;

        // Get view distance
        float viewDist = length(viewPos);

        // Get normalized eyePlayerPos
        vec3 nEyePlayerPos = eyePlayerPos / viewDist;

        // Get scene color
        vec3 sceneCol = texelFetch(gcolor, screenTexelCoord, 0).rgb;

        // If sky, do full sky render
        if(skyMask){
            sceneCol = getSkyRender(nEyePlayerPos, sceneCol, false) * exp2(-far * (blindness + darknessFactor));
        }
        // Else, calculate reflection and fog
        else{
            #if OUTLINES != 0
                // Outline calculation
                sceneCol *= 1.0 + getOutline(screenTexelCoord, viewPos.z, OUTLINE_PIX_SIZE) * OUTLINE_BRIGHTNESS;
            #endif

            #ifdef SSAO
                // Apply ambient occlusion with simple blur
                sceneCol *= getSSAOBoxBlur(screenTexelCoord);
            #endif

            // Do basic sky render and use it as fog color
            sceneCol = getFogRender(sceneCol, getSkyRender(nEyePlayerPos), viewDist, nEyePlayerPos.y, eyePlayerPos.y + gbufferModelViewInverse[3].y + cameraPosition.y);
        }

    /* DRAWBUFFERS:0 */
        gl_FragData[0] = vec4(sceneCol, 1); // gcolor
    }
#endif