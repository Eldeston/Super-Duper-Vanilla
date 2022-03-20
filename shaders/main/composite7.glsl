#ifdef FRAGMENT
    // For the use of texture2DLod in FXAA.glsl
    #extension GL_ARB_shader_texture_lod : enable
#endif

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
    #if ANTI_ALIASING != 0
        uniform float viewWidth;
        uniform float viewHeight;
    #endif

    #if ANTI_ALIASING == 1
        const bool gcolorMipmapEnabled = true;

        #include "/lib/antialiasing/fxaa.glsl"
    #elif ANTI_ALIASING == 2
        uniform sampler2D depthtex0;
        uniform sampler2D colortex6;

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

    uniform sampler2D gcolor;

    void main(){
        #if ANTI_ALIASING == 1
            vec3 color = textureFXAA(gcolor, texCoord, vec2(viewWidth, viewHeight));
        #elif ANTI_ALIASING == 2
            vec3 color = textureTAA(gcolor, colortex6, texCoord, vec2(viewWidth, viewHeight));

            #ifdef AUTO_EXPOSURE
                #define TEMP_EXPOSURE_DATA texture2D(colortex6, texCoord).a
            #else
                #define TEMP_EXPOSURE_DATA 0
            #endif
        #else
            vec3 color = texture2D(gcolor, texCoord).rgb;
        #endif
        
    /* DRAWBUFFERS:0 */
        gl_FragData[0] = vec4(color, 1); //gcolor

        #if ANTI_ALIASING == 2
        /* DRAWBUFFERS:06 */
            gl_FragData[1] = vec4(color, TEMP_EXPOSURE_DATA); //colortex6
        #endif
    }
#endif