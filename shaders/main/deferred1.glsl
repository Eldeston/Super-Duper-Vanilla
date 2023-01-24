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

    out vec3 skyCol;

    #ifdef WORLD_LIGHT
        out vec3 sRGBLightCol;
        out vec3 lightCol;
    #endif

    #ifndef FORCE_DISABLE_WEATHER
        uniform float rainStrength;
    #endif

    #ifndef FORCE_DISABLE_DAY_CYCLE
        uniform float dayCycleAdjust;
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

    in vec3 skyCol;

    #ifdef WORLD_LIGHT
        in vec3 sRGBLightCol;
        in vec3 lightCol;
    #endif
    
    // Sky silhoutte fix
    const vec4 gcolorClearColor = vec4(0, 0, 0, 1);

    uniform int isEyeInWater;

    uniform float far;

    uniform float blindness;
    uniform float nightVision;
    uniform float darknessFactor;

    uniform float frameTimeCounter;

    uniform vec3 fogColor;

    uniform mat4 gbufferProjectionInverse;

    uniform mat4 gbufferModelViewInverse;

    uniform mat4 shadowModelView;

    uniform sampler2D gcolor;
    uniform sampler2D colortex2;
    uniform sampler2D colortex4;
    
    uniform sampler2D depthtex0;

    #ifdef WORLD_LIGHT
        uniform float shdFade;
    #endif

    #ifndef FORCE_DISABLE_WEATHER
        uniform float rainStrength;
    #endif

    #ifndef FORCE_DISABLE_DAY_CYCLE
        uniform float dayCycleAdjust;
    #endif

    #ifdef WORLD_SKYLIGHT
        const float eyeBrightFact = WORLD_SKYLIGHT;
    #else
        uniform ivec2 eyeBrightnessSmooth;
        
        float eyeBrightFact = eyeBrightnessSmooth.y * 0.00416667;
    #endif

    #ifdef SSAO
        float getSSAOBoxBlur(in ivec2 screenTexelCoord){
            ivec2 topRightCorner = screenTexelCoord + 1;
            ivec2 bottomLeftCorner = screenTexelCoord - 1;

            float sample0 = texelFetch(colortex2, topRightCorner, 0).a;
            float sample1 = texelFetch(colortex2, bottomLeftCorner, 0).a;
            float sample2 = texelFetch(colortex2, ivec2(topRightCorner.x, bottomLeftCorner.y), 0).a;
            float sample3 = texelFetch(colortex2, ivec2(bottomLeftCorner.x, topRightCorner.y), 0).a;

            float sumDepth = sample0 + sample1 + sample2 + sample3;

            return sumDepth * 0.25;
        }
    #endif

    #include "/lib/utility/convertViewSpace.glsl"

    #include "/lib/utility/noiseFunctions.glsl"

    #include "/lib/atmospherics/skyRender.glsl"

    void main(){
        // Screen texel coordinates
        ivec2 screenTexelCoord = ivec2(gl_FragCoord.xy);
        // Declare and get positions
        vec3 screenPos = vec3(texCoord, texelFetch(depthtex0, screenTexelCoord, 0).x);
        vec3 viewPos = toView(screenPos);
        vec3 eyePlayerPos = mat3(gbufferModelViewInverse) * viewPos;

        float viewDist = length(viewPos);

        vec3 nEyePlayerPos = eyePlayerPos / viewDist;
        
        // Get sky mask
        bool skyMask = screenPos.z == 1;

        // Get scene color
        vec3 sceneCol = texelFetch(gcolor, screenTexelCoord, 0).rgb;

        // If sky, do full sky render
        if(skyMask){
            sceneCol = getSkyRender(sceneCol, nEyePlayerPos, true) * exp2(-far * (blindness + darknessFactor));
        }
        // Else, calculate reflection and fog
        else{
            #ifdef SSAO
                // Apply ambient occlusion with simple blur
                sceneCol *= getSSAOBoxBlur(screenTexelCoord);
            #endif
        }

    /* DRAWBUFFERS:0 */
        gl_FragData[0] = vec4(sceneCol, 1); // gcolor
    }
#endif