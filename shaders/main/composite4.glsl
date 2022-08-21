/// ------------------------------------- /// Vertex Shader /// ------------------------------------- ///

#ifdef VERTEX
    out vec2 screenCoord;

    void main(){
        gl_Position = ftransform();
        screenCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    }
#endif

/// ------------------------------------- /// Fragment Shader /// ------------------------------------- ///

#ifdef FRAGMENT
    in vec2 screenCoord;

    #ifdef BLOOM
        // Needs to be enabled by force to be able to use LOD fully even with texture2DLod
        const bool gcolorMipmapEnabled = true;
        
        uniform sampler2D gcolor;

        uniform float viewWidth;

        vec3 bloomTile(vec2 coords, float LOD){
            float scale = exp2(LOD);
            vec2 bloomUv = (screenCoord - coords) * scale;
            float padding = 0.5 + 0.005 * scale;

            if(abs(bloomUv.x - 0.5) < padding && abs(bloomUv.y - 0.5) < padding){
                // Get pixel size based on bloom tile scale
                float pixSize = scale / viewWidth;
                
                vec3 sample0 = texture2DLod(gcolor, bloomUv + vec2(pixSize * 2.0, 0), LOD).rgb +
                    texture2DLod(gcolor, bloomUv - vec2(pixSize * 2.0, 0), LOD).rgb;
                vec3 sample1 = texture2DLod(gcolor, bloomUv + vec2(pixSize, 0), LOD).rgb +
                    texture2DLod(gcolor, bloomUv - vec2(pixSize, 0), LOD).rgb;
                vec3 sample2 = texture2DLod(gcolor, bloomUv, LOD).rgb;

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
            eBloom += bloomTile(vec2(0.160625, 0.3625), 7.0);
        
        /* DRAWBUFFERS:4 */
            gl_FragData[0] = vec4(eBloom, 1); //colortex4
        #else
        /* DRAWBUFFERS:4 */
            gl_FragData[0] = vec4(0, 0, 0, 1); //colortex4
        #endif
    }
#endif