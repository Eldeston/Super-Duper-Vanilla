/*
================================ /// Super Duper Vanilla v1.3.5 /// ================================

    Developed by Eldeston, presented by FlameRender (C) Studios.

    Copyright (C) 2023 Eldeston | FlameRender (C) Studios License


    By downloading this content you have agreed to the license and its terms of use.

================================ /// Super Duper Vanilla v1.3.5 /// ================================
*/

/// Buffer features: TAA jittering, and direct shading

/// -------------------------------- /// Vertex Shader /// -------------------------------- ///

#ifdef VERTEX
    flat out float vertexAlpha;

    flat out vec3 vertexColor;

    out vec2 texCoord;

    #if ANTI_ALIASING == 2
        uniform int frameMod8;

        uniform float pixelWidth;
        uniform float pixelHeight;

        #include "/lib/utility/taaJitter.glsl"
    #endif

    void main(){
        // Get vertex alpha
        vertexAlpha = gl_Color.a;
        // Get vertex color
        vertexColor = gl_Color.rgb;
        // Get buffer texture coordinates
        texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

        gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;

        #if ANTI_ALIASING == 2
            gl_Position.xy += jitterPos(gl_Position.w);
        #endif
    }
#endif

/// -------------------------------- /// Fragment Shader /// -------------------------------- ///

#ifdef FRAGMENT
    /* RENDERTARGETS: 0 */
    layout(location = 0) out vec3 sceneColOut; // gcolor

    flat in float vertexAlpha;

    flat in vec3 vertexColor;

    in vec2 texCoord;

    uniform sampler2D tex;

    #if defined MC_RENDER_STAGE_SUN || defined MC_RENDER_STAGE_MOON
        uniform int renderStage;
    #endif

    #if WORLD_SUN_MOON == 1 && SUN_MOON_TYPE == 2 && defined WORLD_LIGHT && !defined FORCE_DISABLE_DAY_CYCLE
        uniform float dayCycle;
        uniform float twilightPhase;
    #endif
    
    void main(){
        // Get albedo color
        vec4 albedo = textureLod(tex, texCoord, 0);

        // Alpha test, discard immediately
        if(albedo.a < ALPHA_THRESHOLD) discard;

    /* DRAWBUFFERS:0 */
        // Detect sun
        #ifdef MC_RENDER_STAGE_SUN
            #if WORLD_SUN_MOON == 1 && SUN_MOON_TYPE == 2 && defined WORLD_LIGHT && !defined FORCE_DISABLE_DAY_CYCLE
                if(renderStage == MC_RENDER_STAGE_SUN){
                    sceneColOut = toLinear(albedo.rgb * (SUN_MOON_INTENSITY * vertexAlpha)) * SUN_COL_DATA_BLOCK;
                    return;
                }
            #else
                if(renderStage == MC_RENDER_STAGE_MOON) discard;
            #endif
        #endif

        // Detect moon
        #ifdef MC_RENDER_STAGE_MOON
            #if WORLD_SUN_MOON == 1 && SUN_MOON_TYPE == 2 && defined WORLD_LIGHT && !defined FORCE_DISABLE_DAY_CYCLE
                if(renderStage == MC_RENDER_STAGE_MOON){
                    sceneColOut = toLinear(albedo.rgb * (SUN_MOON_INTENSITY * vertexAlpha)) * MOON_COL_DATA_BLOCK;
                    return;
                }
            #else
                if(renderStage == MC_RENDER_STAGE_MOON) discard;
            #endif
        #endif

        // Otherwise, calculate skybox
        sceneColOut = toLinear(albedo.rgb * vertexColor * (SKYBOX_BRIGHTNESS * vertexAlpha));
    }
#endif