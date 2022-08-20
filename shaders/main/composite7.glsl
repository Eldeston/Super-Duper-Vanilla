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

    uniform sampler2D gcolor;

    #if ANTI_ALIASING == 1 || ANTI_ALIASING == 3
        uniform float viewWidth;
        uniform float viewHeight;

        #include "/lib/antialiasing/fxaa.glsl"
    #endif

    void main(){
        #if ANTI_ALIASING == 1 || ANTI_ALIASING == 3
            vec3 color = textureFXAA(screenCoord, vec2(viewWidth, viewHeight), ivec2(gl_FragCoord.xy));
        #else
            vec3 color = texelFetch(gcolor, ivec2(gl_FragCoord.xy), 0).rgb;
        #endif
        
    /* DRAWBUFFERS:0 */
        gl_FragData[0] = vec4(color, 1); // gcolor
    }
#endif