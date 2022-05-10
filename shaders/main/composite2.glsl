varying vec2 screenCoord;

#ifdef VERTEX
    void main(){
        gl_Position = ftransform();
        screenCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    }
#endif

#ifdef FRAGMENT
    uniform sampler2D gcolor;

    #ifdef MOTION_BLUR
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

        #include "/lib/utility/noiseFunctions.glsl"

        #include "/lib/post/motionBlur.glsl"
    #endif

    void main(){
        vec3 sceneCol = texture2D(gcolor, screenCoord).rgb;

        #ifdef MOTION_BLUR
            float depth = texture2D(depthtex0, screenCoord).x;

            if(depth > 0.56) sceneCol = motionBlur(sceneCol, screenCoord, depth, texture2D(noisetex, gl_FragCoord.xy * 0.03125).x);
        #endif

    /* DRAWBUFFERS:0 */
        gl_FragData[0] = vec4(sceneCol, 1); // gcolor
    }
#endif