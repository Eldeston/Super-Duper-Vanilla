/*
================================ /// Super Duper Vanilla v1.3.8 /// ================================

    Developed by Eldeston, presented by FlameRender (C) Studios.

    Copyright (C) 2023 Eldeston | FlameRender (C) Studios License


    By downloading this content you have agreed to the license and its terms of use.

================================ /// Super Duper Vanilla v1.3.8 /// ================================
*/

/// Buffer features: Bloom blur 2nd pass

/// -------------------------------- /// Vertex Shader /// -------------------------------- ///

#ifdef VERTEX
    void main(){
        gl_Position = vec4(gl_Vertex.xy * 2.0 - 1.0, 0, 1);
    }
#endif

/// -------------------------------- /// Fragment Shader /// -------------------------------- ///

#ifdef FRAGMENT
    /* RENDERTARGETS: 0 */
    layout(location = 0) out vec3 bloomColOut; // colortex0

    #ifdef BLOOM
        // No need to use mipmapping in this 2nd bloom pass, so we'll utilize texelFetch for some sweet, sweet performance
        uniform sampler2D colortex0;
    #endif

    void main(){
        #ifdef BLOOM
            vec3 sample0 = texelFetch(colortex0, ivec2(gl_FragCoord.x, gl_FragCoord.y - 2), 0).rgb +
                texelFetch(colortex0, ivec2(gl_FragCoord.x, gl_FragCoord.y + 2), 0).rgb;
            vec3 sample1 = texelFetch(colortex0, ivec2(gl_FragCoord.x, gl_FragCoord.y - 1), 0).rgb +
                texelFetch(colortex0, ivec2(gl_FragCoord.x, gl_FragCoord.y + 1), 0).rgb;
            vec3 sample2 = texelFetch(colortex0, ivec2(gl_FragCoord.xy), 0).rgb;

            bloomColOut = sample0 * 0.0625 + sample1 * 0.25 + sample2 * 0.375;
        #else
            bloomColOut = vec3(0);
        #endif
    }
#endif