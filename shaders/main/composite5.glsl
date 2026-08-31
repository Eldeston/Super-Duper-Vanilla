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

        // Needs to be enabled by force to be able to use LOD fully even with textureLod
        const bool colortex0MipmapEnabled = false;

        // No need to use mipmapping in this 2nd bloom pass, so we'll utilize texelFetch for some sweet, sweet performance
        uniform sampler2D colortex0;

        uniform float pixelWidth;

        bool isBloomTile(in vec3 bloomCol, in vec2 bloomPos, in int scale, in int LOD){
            // Get bloom UV
            vec2 bloomUv = bloomPos * scale;

            // Apply padding
            if(bloomUv.x < 0 || bloomUv.x > 1 || bloomUv.y < 0 || bloomUv.y > 1) return true;

            // Output bloom
            return false;
        }
    #endif

    void main(){
        #ifdef BLOOM
            // Skip empty spaces
            if(
                isBloomTile(vec3(0), texCoord, 4, 2) &&
                isBloomTile(bloomColOut, vec2(texCoord.x, texCoord.y - 0.2578125), 8, 3) &&
                isBloomTile(bloomColOut, vec2(texCoord.x - 0.12890625, texCoord.y - 0.2578125), 16, 4) &&
                isBloomTile(bloomColOut, vec2(texCoord.x - 0.1953125, texCoord.y - 0.2578125), 32, 5) &&
                isBloomTile(bloomColOut, vec2(texCoord.x - 0.12890625, texCoord.y - 0.328125), 64, 6)
            ){
                bloomColOut = vec3(0);
                return;
            }

            // Optimized 9x9 gaussian blur with only 5 texture fetches
            // Technique from https://www.rastergrid.com/blog/2010/09/efficient-gaussian-blur-with-linear-sampling/

            vec3 sample0 = textureLod(colortex0, vec2(texCoord.x - pixelWidth * 3.2307692308, texCoord.y), 0).rgb +
                textureLod(colortex0, vec2(texCoord.x + pixelWidth * 3.2307692308, texCoord.y), 0).rgb;
            vec3 sample1 = textureLod(colortex0, vec2(texCoord.x - pixelWidth * 1.3846153846, texCoord.y), 0).rgb +
                textureLod(colortex0, vec2(texCoord.x + pixelWidth * 1.3846153846, texCoord.y), 0).rgb;
            vec3 center = textureLod(colortex0, texCoord.xy, 0).rgb;

            bloomColOut = sample0 * 0.0702702703 + sample1 * 0.3162162162 + center * 0.2270270270;
        #else
            bloomColOut = vec3(0);
        #endif
    }
#endif