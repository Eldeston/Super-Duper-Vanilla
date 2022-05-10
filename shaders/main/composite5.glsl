varying vec2 screenCoord;

#ifdef VERTEX
    void main(){
        gl_Position = ftransform();
        screenCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    }
#endif

#ifdef FRAGMENT
    #ifdef BLOOM
        const bool colortex4MipmapEnabled = true;

        uniform sampler2D colortex4;

        uniform float viewHeight;
    #endif

    void main(){
        #ifdef BLOOM
            // Get pixel size
            float pixSize = 1.0 / viewHeight;

            vec3 eBloom = (texture2D(colortex4, screenCoord + vec2(0, pixSize * 2.0)).rgb +
                texture2D(colortex4, screenCoord - vec2(0, pixSize * 2.0)).rgb) * 0.0625;
            eBloom += (texture2D(colortex4, screenCoord + vec2(0, pixSize)).rgb +
                texture2D(colortex4, screenCoord - vec2(0, pixSize)).rgb) * 0.25;
            eBloom += texture2D(colortex4, screenCoord).rgb * 0.375;
            
        /* DRAWBUFFERS:4 */
            gl_FragData[0] = vec4(eBloom, 1); //colortex4
        #else
        /* DRAWBUFFERS:4 */
            gl_FragData[0] = vec4(0, 0, 0, 1); //colortex4
        #endif
    }
#endif