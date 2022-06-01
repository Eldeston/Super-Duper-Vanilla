varying vec2 screenCoord;

#ifdef VERTEX
    void main(){
        gl_Position = ftransform();
        screenCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    }
#endif

#ifdef FRAGMENT
    uniform sampler2D gcolor;

    #if ANTI_ALIASING == 1 || ANTI_ALIASING == 2
        const bool gcolorMipmapEnabled = true;

        uniform float viewWidth;
        uniform float viewHeight;

        #include "/lib/antialiasing/fxaa.glsl"
    #endif

    void main(){
        #if ANTI_ALIASING == 1 || ANTI_ALIASING == 2
            vec3 color = textureFXAA(screenCoord, vec2(viewWidth, viewHeight));
        #else
            vec3 color = texture2D(gcolor, screenCoord).rgb;
        #endif
        
    /* DRAWBUFFERS:0 */
        gl_FragData[0] = vec4(color, 1); // gcolor
    }
#endif