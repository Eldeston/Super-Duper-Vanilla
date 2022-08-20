/// ------------------------------------- /// Vertex Shader /// ------------------------------------- ///

#ifdef VERTEX
    void main(){
        gl_Position = ftransform();
    }
#endif

/// ------------------------------------- /// Fragment Shader /// ------------------------------------- ///

#ifdef FRAGMENT
    #ifdef BLOOM
        // No need to enable mipmapping to use LOD for texture2DLod as we're only using 0 LOD anyway
        uniform sampler2D colortex4;
    #endif

    void main(){
        #ifdef BLOOM
            // Screen texel coordinates
            ivec2 screenTexelCoord = ivec2(gl_FragCoord.xy);

            vec3 sample0 = texelFetch(colortex4, ivec2(screenTexelCoord.x, screenTexelCoord.y + 2), 0).rgb +
                texelFetch(colortex4, ivec2(screenTexelCoord.x, screenTexelCoord.y - 2), 0).rgb;
            vec3 sample1 = texelFetch(colortex4, ivec2(screenTexelCoord.x, screenTexelCoord.y + 1), 0).rgb +
                texelFetch(colortex4, ivec2(screenTexelCoord.x, screenTexelCoord.y - 1), 0).rgb;
            vec3 sample2 = texelFetch(colortex4, screenTexelCoord, 0).rgb;

            vec3 eBloom = sample0 * 0.0625 + sample1 * 0.25 + sample2 * 0.375;
            
        /* DRAWBUFFERS:4 */
            gl_FragData[0] = vec4(eBloom, 1); // colortex4
        #else
        /* DRAWBUFFERS:4 */
            gl_FragData[0] = vec4(0, 0, 0, 1); // colortex4
        #endif
    }
#endif