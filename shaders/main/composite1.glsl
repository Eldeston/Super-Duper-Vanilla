varying vec2 screenCoord;

#ifdef VERTEX
    void main(){
        gl_Position = ftransform();
        screenCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    }
#endif

#ifdef FRAGMENT
    uniform sampler2D gcolor;

    #if ANTI_ALIASING >= 2 || (defined PREVIOUS_FRAME && defined SSR && defined SSGI)
        uniform sampler2D colortex5;
    #endif

    #if ANTI_ALIASING >= 2
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
    #endif

    void main(){
        #if ANTI_ALIASING >= 2
            vec3 sceneCol = textureTAA(ivec2(gl_FragCoord.xy), screenCoord);
        #else
            vec3 sceneCol = texelFetch(gcolor, ivec2(gl_FragCoord.xy), 0).rgb;
        #endif

    /* DRAWBUFFERS:0 */
        gl_FragData[0] = vec4(sceneCol, 1); // gcolor

        #if ANTI_ALIASING >= 2 || (defined PREVIOUS_FRAME && defined SSR && defined SSGI)
        /* DRAWBUFFERS:05 */
            #ifdef AUTO_EXPOSURE
                gl_FragData[1] = vec4(sceneCol, texelFetch(colortex5, ivec2(0), 0).a); // colortex5
            #else
                gl_FragData[1] = vec4(sceneCol, 1); // colortex5
            #endif
        #endif
    }
#endif