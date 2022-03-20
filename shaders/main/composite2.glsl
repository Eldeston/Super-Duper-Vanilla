#include "/lib/utility/util.glsl"
#include "/lib/settings.glsl"

varying vec2 texCoord;

#ifdef VERTEX
    void main(){
        gl_Position = ftransform();
        texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    }
#endif

#ifdef FRAGMENT
    uniform sampler2D gcolor;

    #ifdef MOTION_BLUR
        uniform sampler2D depthtex0;
        
        /* Screen resolutions */
        uniform float viewWidth;
        uniform float viewHeight;

        #if ANTI_ALIASING == 2
            uniform float frameTimeCounter;
        #endif

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
        vec3 sceneCol = texture2D(gcolor, texCoord).rgb;

        #ifdef MOTION_BLUR
            if(texture2D(depthtex0, texCoord).x >= 0.56){
                #if ANTI_ALIASING == 2
                    float dither = toRandPerFrame(getRand1(gl_FragCoord.xy * 0.03125), frameTimeCounter);
                #else
                    float dither = getRand1(gl_FragCoord.xy * 0.03125);
                #endif

                sceneCol = motionBlur(sceneCol, texCoord, dither);
            }
        #endif

    /* DRAWBUFFERS:0 */
        gl_FragData[0] = vec4(sceneCol, 1); // gcolor
    }
#endif