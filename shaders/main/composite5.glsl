/*
================================ /// Super Duper Vanilla v1.3.4 /// ================================

    Developed by Eldeston, presented by FlameRender (TM) Studios.

    Copyright (C) 2023 Eldeston | FlameRender (TM) Studios License


    By downloading this content you have agreed to the license and its terms of use.

================================ /// Super Duper Vanilla v1.3.4 /// ================================
*/

/// Buffer features: Bloom blur 2nd pass

/// -------------------------------- /// Vertex Shader /// -------------------------------- ///

#ifdef VERTEX
    void main(){
        gl_Position = ftransform();
    }
#endif

/// -------------------------------- /// Fragment Shader /// -------------------------------- ///

#ifdef FRAGMENT
    #ifdef BLOOM
        // No need to use mipmapping in this 2nd bloom pass, so we'll utilize texelFetch for some sweet, sweet performance
        uniform sampler2D colortex4;
    #endif

    void main(){
        #ifdef BLOOM
            vec3 sample0 = texelFetch(colortex4, ivec2(gl_FragCoord.x, gl_FragCoord.y - 2), 0).rgb +
                texelFetch(colortex4, ivec2(gl_FragCoord.x, gl_FragCoord.y + 2), 0).rgb;
            vec3 sample1 = texelFetch(colortex4, ivec2(gl_FragCoord.x, gl_FragCoord.y - 1), 0).rgb +
                texelFetch(colortex4, ivec2(gl_FragCoord.x, gl_FragCoord.y + 1), 0).rgb;
            vec3 sample2 = texelFetch(colortex4, ivec2(gl_FragCoord.xy), 0).rgb;

            vec3 finalCol = sample0 * 0.0625 + sample1 * 0.25 + sample2 * 0.375;
            
        /* DRAWBUFFERS:4 */
            gl_FragData[0] = vec4(finalCol, 1); // colortex4
        #else
        /* DRAWBUFFERS:4 */
            gl_FragData[0] = vec4(0, 0, 0, 1); // colortex4
        #endif
    }
#endif