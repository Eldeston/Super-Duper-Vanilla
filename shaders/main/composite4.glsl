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

        vec3 bloomTile(in vec2 coords, in float LOD){
            float scale = exp2(LOD);
            vec2 bloomUv = (texCoord - coords) * scale;
            float padding = 0.5 + 0.005 * scale;

            if(abs(bloomUv.x - 0.5) < padding && abs(bloomUv.y - 0.5) < padding){
                // Get pixel size based on bloom tile scale
                float pixSize = scale / viewWidth;
                
                vec3 sample0 = textureLod(gcolor, bloomUv + vec2(pixSize * 2.0, 0), LOD).rgb +
                    textureLod(gcolor, bloomUv - vec2(pixSize * 2.0, 0), LOD).rgb;
                vec3 sample1 = textureLod(gcolor, bloomUv + vec2(pixSize, 0), LOD).rgb +
                    textureLod(gcolor, bloomUv - vec2(pixSize, 0), LOD).rgb;
                vec3 sample2 = textureLod(gcolor, bloomUv, LOD).rgb;

                return sample0 * 0.0625 + sample1 * 0.25 + sample2 * 0.375;
            }
            
            return vec3(0);
        }
    #endif

    void main(){
        #ifdef BLOOM
            vec3 eBloom = bloomTile(vec2(0), 2.0);
            eBloom += bloomTile(vec2(0, 0.275), 3.0);
            eBloom += bloomTile(vec2(0.135, 0.275), 4.0);
            eBloom += bloomTile(vec2(0.2075, 0.275), 5.0);
            eBloom += bloomTile(vec2(0.135, 0.3625), 6.0);
        
        /* DRAWBUFFERS:4 */
            gl_FragData[0] = vec4(eBloom, 1); //colortex4
        #else
        /* DRAWBUFFERS:4 */
            gl_FragData[0] = vec4(0, 0, 0, 1); //colortex4
        #endif
    }
#endif