varying vec2 screenCoord;

#ifdef VERTEX
    void main(){
        gl_Position = ftransform();
        screenCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    }
#endif

#ifdef FRAGMENT
    #if ANTI_ALIASING != 0
        uniform float viewWidth;
        uniform float viewHeight;
    #endif

    #if ANTI_ALIASING == 1
        const bool gcolorMipmapEnabled = true;

        uniform sampler2D gcolor;

        #include "/lib/antialiasing/fxaa.glsl"
    #elif ANTI_ALIASING == 2
        uniform sampler2D gcolor;
        uniform sampler2D colortex6;
        uniform sampler2D depthtex0;

        /* Matrix uniforms */
        // View matrix uniforms
        uniform mat4 gbufferModelViewInverse;
        uniform mat4 gbufferPreviousModelView;

        // Projection matrix uniforms
        uniform mat4 gbufferProjectionInverse;
        uniform mat4 gbufferPreviousProjection;

        /* Position uniforms */
        uniform vec3 cameraPosition;
        uniform vec3 previousCameraPosition;

        #include "/lib/utility/convertPrevScreenSpace.glsl"

        #include "/lib/antialiasing/taa.glsl"
    #else
        uniform sampler2D gcolor;
    #endif

    void main(){
        #if ANTI_ALIASING == 1
            vec3 color = textureFXAA(screenCoord, vec2(viewWidth, viewHeight));
        #elif ANTI_ALIASING == 2
            vec3 color = textureTAA(screenCoord, vec2(viewWidth, viewHeight));
        #else
            vec3 color = texture2D(gcolor, screenCoord).rgb;
        #endif
        
    /* DRAWBUFFERS:0 */
        gl_FragData[0] = vec4(color, 1); // gcolor

        #if ANTI_ALIASING == 2
            #ifdef AUTO_EXPOSURE
            /* DRAWBUFFERS:06 */
                gl_FragData[1] = vec4(color, texture2D(colortex6, screenCoord).a); //colortex6
            #else
            /* DRAWBUFFERS:06 */
                gl_FragData[1] = vec4(color, 1); //colortex6
            #endif
        #endif
    }
#endif