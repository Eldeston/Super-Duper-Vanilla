/*
================================ /// Super Duper Vanilla v1.3.8 /// ================================

    Developed by Eldeston, presented by FlameRender (C) Studios.

    Copyright (C) 2023 Eldeston | FlameRender (C) Studios License


    By downloading this content you have agreed to the license and its terms of use.

================================ /// Super Duper Vanilla v1.3.8 /// ================================
*/

/// Buffer features: Bloom blur 1st pass

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
        // Needs to be enabled by force to be able to use LOD fully even with textureLod
        const bool colortex4MipmapEnabled = true;

        noperspective in vec2 texCoord;

        uniform float pixelWidth;

        uniform sampler2D colortex4;

        vec3 bloomTile(in vec3 bloomCol, in vec2 bloomPos, in int scale, in int LOD){
            vec2 bloomUv = bloomPos * scale;

            // Apply padding
            if(bloomUv.x < 0 || bloomUv.x > 1 || bloomUv.y < 0 || bloomUv.y > 1) return bloomCol;

            // Get pixel size based on bloom tile scale
            float pixSize = scale * pixelWidth;

            vec3 sample0 = textureLod(colortex4, vec2(bloomUv.x - pixSize * 2.0, bloomUv.y), LOD).rgb +
                textureLod(colortex4, vec2(bloomUv.x + pixSize * 2.0, bloomUv.y), LOD).rgb;
            vec3 sample1 = textureLod(colortex4, vec2(bloomUv.x - pixSize, bloomUv.y), LOD).rgb +
                textureLod(colortex4, vec2(bloomUv.x + pixSize, bloomUv.y), LOD).rgb;
            vec3 sample2 = textureLod(colortex4, bloomUv, LOD).rgb;

            return sample0 * 0.0625 + sample1 * 0.25 + sample2 * 0.375;
        }
    #endif

    void main(){
        #ifdef BLOOM
            bloomColOut = bloomTile(vec3(0), texCoord, 4, 2);
            bloomColOut = bloomTile(bloomColOut, vec2(texCoord.x, texCoord.y - 0.2578125), 8, 3);
            bloomColOut = bloomTile(bloomColOut, vec2(texCoord.x - 0.12890625, texCoord.y - 0.2578125), 16, 4);
            bloomColOut = bloomTile(bloomColOut, vec2(texCoord.x - 0.1953125, texCoord.y - 0.2578125), 32, 5);
            bloomColOut = bloomTile(bloomColOut, vec2(texCoord.x - 0.12890625, texCoord.y - 0.328125), 64, 6);
        #else
            bloomColOut = vec3(0);
        #endif
    }
#endif