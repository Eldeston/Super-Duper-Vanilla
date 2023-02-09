/*
================================ /// Super Duper Vanilla v1.3.3 /// ================================

    Developed by Eldeston, presented by FlameRender (TM) Studios.

    Copyright (C) 2020 Eldeston | FlameRender (TM) Studios License


    By downloading this content you have agreed to the license and its terms of use.

================================ /// Super Duper Vanilla v1.3.3 /// ================================
*/

/// Buffer features: Bloom blur 1st pass

/// -------------------------------- /// Vertex Shader /// -------------------------------- ///

#ifdef VERTEX
    out vec2 texCoord;

    void main(){
        // Get buffer texture coordinates
        texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
        gl_Position = ftransform();
    }
#endif

/// -------------------------------- /// Fragment Shader /// -------------------------------- ///

#ifdef FRAGMENT
    in vec2 texCoord;

    #ifdef BLOOM
        // Needs to be enabled by force to be able to use LOD fully even with textureLod
        const bool gcolorMipmapEnabled = true;

        uniform float viewWidth;

        uniform sampler2D gcolor;

        vec3 bloomTile(in vec2 bloomPos, in float LOD){
            float scale = exp2(LOD);
            vec2 bloomUv = bloomPos * scale;

            if(bloomUv.x >= 0 && bloomUv.x <= 1 && bloomUv.y >= 0 && bloomUv.y <= 1){
                // Get pixel size based on bloom tile scale
                float pixSize = scale / viewWidth;
                
                vec3 sample0 = textureLod(gcolor, vec2(bloomUv.x - pixSize * 2.0, bloomUv.y), LOD).rgb +
                    textureLod(gcolor, vec2(bloomUv.x + pixSize * 2.0, bloomUv.y), LOD).rgb;
                vec3 sample1 = textureLod(gcolor, vec2(bloomUv.x - pixSize, bloomUv.y), LOD).rgb +
                    textureLod(gcolor, vec2(bloomUv.x + pixSize, bloomUv.y), LOD).rgb;
                vec3 sample2 = textureLod(gcolor, bloomUv, LOD).rgb;

                return sample0 * 0.0625 + sample1 * 0.25 + sample2 * 0.375;
            }
            
            return vec3(0);
        }
    #endif

    void main(){
        #ifdef BLOOM
            vec3 eBloom = bloomTile(texCoord, 2.0);
            eBloom += bloomTile(vec2(texCoord.x, texCoord.y - 0.25390625), 3.0);
            eBloom += bloomTile(vec2(texCoord.x - 0.12890625, texCoord.y - 0.25390625), 4.0);
            eBloom += bloomTile(vec2(texCoord.x - 0.19140625, texCoord.y - 0.25390625), 5.0);
            eBloom += bloomTile(vec2(texCoord.x - 0.1328125, texCoord.y - 0.3203125), 6.0);
        
        /* DRAWBUFFERS:4 */
            gl_FragData[0] = vec4(eBloom, 1); //colortex4
        #else
        /* DRAWBUFFERS:4 */
            gl_FragData[0] = vec4(0, 0, 0, 1); //colortex4
        #endif
    }
#endif