/*
================================ /// Super Duper Vanilla v1.3.9 /// ================================

    Developed by Eldeston, presented by FlameRender (C) Studios.

    Copyright (C) 2025 Eldeston | FlameRender (C) Studios License


    By downloading this content you have agreed to the license and its terms of use.

================================ /// Super Duper Vanilla v1.3.9 /// ================================
*/

/// Buffer features: Bloom upscaling and application

/// -------------------------------- /// Vertex Shader /// -------------------------------- ///

#ifdef VERTEX
    void main(){
        gl_Position = vec4(gl_Vertex.xy * 2.0 - 1.0, 0, 1);
    }
#endif

/// -------------------------------- /// Fragment Shader /// -------------------------------- ///

#ifdef FRAGMENT
    /* RENDERTARGETS: 4 */
    layout(location = 0) out vec3 sceneColOut; // colortex4

    uniform sampler2D colortex4;

    #if defined LENS_FLARE && WORLD_LIGHT == 1 || defined BLOOM
        uniform sampler2D colortex0;
    #endif

    void main(){
        // Screen texel coordinates
        ivec2 screenTexelCoord = ivec2(gl_FragCoord.xy);

        // Get scene color
        sceneColOut = texelFetch(colortex4, screenTexelCoord, 0).rgb;

        #if defined LENS_FLARE && WORLD_LIGHT == 1 || defined BLOOM
            // Uncompress the HDR colors and upscale
            vec3 bloomCol = texelFetch(colortex0, ivec2(gl_FragCoord.xy * 0.5), 0).rgb;
            float bloomLuma = sumOf(bloomCol);
            sceneColOut += (bloomCol - sceneColOut) * ((BLOOM_STRENGTH * bloomLuma) / (3.0 + bloomLuma));
        #endif
    }
#endif