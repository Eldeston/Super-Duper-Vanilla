/*
================================ /// Super Duper Vanilla v1.3.3 /// ================================

    Developed by Eldeston, presented by FlameRender (TM) Studios.

    Copyright (C) 2020 Eldeston | FlameRender (TM) Studios License


    By downloading this content you have agreed to the license and its terms of use.

================================ /// Super Duper Vanilla v1.3.3 /// ================================
*/

/// Buffer features: TAA jittering, and direct shading

/// -------------------------------- /// Vertex Shader /// -------------------------------- ///

#ifdef VERTEX
    flat out float vertexAlpha;

    out vec2 texCoord;

    #if ANTI_ALIASING == 2
        uniform float viewWidth;
        uniform float viewHeight;

        #include "/lib/utility/taaJitter.glsl"
    #endif

    void main(){
        // Get buffer texture coordinates
        texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

        gl_Position = ftransform();

        #if ANTI_ALIASING == 2
            gl_Position.xy += jitterPos(gl_Position.w);
        #endif

        vertexAlpha = gl_Color.a;
    }
#endif

/// -------------------------------- /// Fragment Shader /// -------------------------------- ///

#ifdef FRAGMENT
    flat in float vertexAlpha;

    in vec2 texCoord;

    uniform int renderStage;

    uniform sampler2D tex;

    #ifndef FORCE_DISABLE_WEATHER
        uniform float rainStrength;
    #endif

    #if WORLD_SUN_MOON == 1 && SUN_MOON_TYPE == 2 && defined WORLD_LIGHT && !defined FORCE_DISABLE_DAY_CYCLE
        uniform float dayCycle;
    #endif
    
    void main(){
        // Get albedo color
        vec4 albedo = textureLod(tex, texCoord, 0);

        // Alpha test, discard immediately
        if(albedo.a <= ALPHA_THRESHOLD) discard;

    /* DRAWBUFFERS:0 */
        // Detect and calculate the sun and moon
        if(renderStage == MC_RENDER_STAGE_SUN || renderStage == MC_RENDER_STAGE_MOON)
            #if WORLD_SUN_MOON == 1 && SUN_MOON_TYPE == 2 && defined WORLD_LIGHT
                gl_FragData[0] = vec4((SUN_MOON_INTENSITY * SUN_MOON_INTENSITY * vertexAlpha) * toLinear(albedo.rgb) * LIGHT_COL_DATA_BLOCK, albedo.a);
            #else
                discard;
            #endif
        // Otherwise, calculate skybox
        else gl_FragData[0] = vec4(toLinear(albedo.rgb) * (SKYBOX_BRIGHTNESS * vertexAlpha), albedo.a);
    }
#endif