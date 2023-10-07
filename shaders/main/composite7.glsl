/*
================================ /// Super Duper Vanilla v1.3.5 /// ================================

    Developed by Eldeston, presented by FlameRender (C) Studios.

    Copyright (C) 2023 Eldeston | FlameRender (C) Studios License


    By downloading this content you have agreed to the license and its terms of use.

================================ /// Super Duper Vanilla v1.3.5 /// ================================
*/

/// Buffer features: Fast Approximate Anti-Aliasing (FXAA)

/// -------------------------------- /// Vertex Shader /// -------------------------------- ///

#ifdef VERTEX
    noperspective out vec2 texCoord;

    void main(){
        // Get buffer texture coordinates
        texCoord = gl_MultiTexCoord0.xy;

        gl_Position = vec4(gl_Vertex.xy * 2.0 - 1.0, 0, 1);
    }
#endif

/// -------------------------------- /// Fragment Shader /// -------------------------------- ///

#ifdef FRAGMENT
    /* RENDERTARGETS: 3 */
    layout(location = 0) out vec3 postColOut; // colortex3

    noperspective in vec2 texCoord;

    uniform sampler2D colortex3;

    #if ANTI_ALIASING == 1 || ANTI_ALIASING == 3
        uniform float pixelWidth;
        uniform float pixelHeight;

        #include "/lib/antialiasing/fxaa.glsl"
    #endif

    void main(){
        #if ANTI_ALIASING == 1 || ANTI_ALIASING == 3
            postColOut = textureFXAA(ivec2(gl_FragCoord.xy));
        #else
            postColOut = texelFetch(colortex3, ivec2(gl_FragCoord.xy), 0).rgb;
        #endif
    }
#endif