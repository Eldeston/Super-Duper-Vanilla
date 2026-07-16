/*
================================ /// Super Duper Vanilla v1.3.9 /// ================================

    Developed by Eldeston, presented by FlameRender (C) Studios.

    Copyright (C) 2025 Eldeston | FlameRender (C) Studios License


    By downloading this content you have agreed to the license and its terms of use.

================================ /// Super Duper Vanilla v1.3.9 /// ================================
*/

/// Buffer features: Bloom blur 2nd pass

/// -------------------------------- /// Vertex Shader /// -------------------------------- ///

#ifdef VERTEX
    #ifdef BLOOM
        noperspective out vec2 texCoord;
    #endif

    void main(){
        #ifdef BLOOM
            // Get buffer texture coordinates
            texCoord = gl_MultiTexCoord0.xy;
        #endif

        gl_Position = vec4(gl_Vertex.xy * 2.0 - 1.0, 0, 1);
    }
#endif

/// -------------------------------- /// Fragment Shader /// -------------------------------- ///

#ifdef FRAGMENT
    /* RENDERTARGETS: 0 */
    layout(location = 0) out vec3 bloomColOut; // colortex0

    #ifdef BLOOM
        noperspective in vec2 texCoord;

        // No need to use mipmapping in this 2nd bloom pass, so we'll utilize texelFetch for some sweet, sweet performance
        uniform sampler2D colortex0;

        uniform float pixelHeight;
    #endif

    void main(){
        #ifdef BLOOM
            vec3 sample0 = textureLod(colortex0, vec2(texCoord.x, texCoord.y - pixelHeight * 3.2307692308), 0).rgb +
                textureLod(colortex0, vec2(texCoord.x, texCoord.y + pixelHeight * 3.2307692308), 0).rgb;
            vec3 sample1 = textureLod(colortex0, vec2(texCoord.x, texCoord.y - pixelHeight * 1.3846153846), 0).rgb +
                textureLod(colortex0, vec2(texCoord.x, texCoord.y + pixelHeight * 1.3846153846), 0).rgb;
            vec3 center = textureLod(colortex0, texCoord.xy, 0).rgb;

            bloomColOut = sample0 * 0.0702702703 + sample1 * 0.3162162162 + center * 0.2270270270;
        #else
            bloomColOut = vec3(0);
        #endif
    }
#endif