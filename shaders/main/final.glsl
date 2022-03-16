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
    /* Buffer settings */

    /*
    const int gcolorFormat = R11F_G11F_B10F;
    const int colortex1Format = RGB16;
    const int colortex2Format = RGB8;
    const int colortex3Format = RGB8;
    const int colortex4Format = R11F_G11F_B10F;
    const int colortex5Format = R11F_G11F_B10F;
    const int colortex6Format = RGBA16F;
    const int colortex7Format = RGB8;
    */

    // For Optifine to detect
    #ifdef SHARPENING_FILTER
    #endif

    #if ANTI_ALIASING != 0 && defined SHARPENING_FILTER
        uniform float viewWidth;
        uniform float viewHeight;

        #include "/lib/post/sharpenFilter.glsl"
    #endif

    uniform sampler2D BUFFER_VIEW;

    void main(){
        #if ANTI_ALIASING != 0 && defined SHARPENING_FILTER
            gl_FragColor = vec4(sharpenFilter(BUFFER_VIEW, texCoord), 1); //  final color
        #else
            gl_FragColor = vec4(texture2D(BUFFER_VIEW, texCoord).rgb, 1); //  final color
        #endif
    }
#endif