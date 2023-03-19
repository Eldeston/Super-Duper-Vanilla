/*
================================ /// Super Duper Vanilla v1.3.4 /// ================================

    Developed by Eldeston, presented by FlameRender (TM) Studios.

    Copyright (C) 2023 Eldeston | FlameRender (TM) Studios License


    By downloading this content you have agreed to the license and its terms of use.

================================ /// Super Duper Vanilla v1.3.4 /// ================================
*/

/// Buffer features: Fast Approximate Anti-Aliasing (FXAA)

/// -------------------------------- /// Vertex Shader /// -------------------------------- ///

#ifdef VERTEX
    out vec2 texCoord;

    void main(){
        // Get buffer texture coordinates
        texCoord = gl_MultiTexCoord0.xy;
        gl_Position = ftransform();
    }
#endif

/// -------------------------------- /// Fragment Shader /// -------------------------------- ///

#ifdef FRAGMENT
    in vec2 texCoord;

    uniform sampler2D colortex3;

    #if ANTI_ALIASING == 1 || ANTI_ALIASING == 3
        uniform float pixelWidth;
        uniform float pixelHeight;

        #include "/lib/antialiasing/fxaa.glsl"
    #endif

    void main(){
        #if ANTI_ALIASING == 1 || ANTI_ALIASING == 3
            vec3 sceneCol = textureFXAA(ivec2(gl_FragCoord.xy));
        #else
            vec3 sceneCol = texelFetch(colortex3, ivec2(gl_FragCoord.xy), 0).rgb;
        #endif
        
    /* DRAWBUFFERS:3 */
        gl_FragData[0] = vec4(sceneCol, 1); // colortex3
    }
#endif