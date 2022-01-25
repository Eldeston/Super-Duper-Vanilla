#include "/lib/utility/util.glsl"
#include "/lib/structs.glsl"
#include "/lib/settings.glsl"

INOUT vec2 texcoord;

#ifdef VERTEX
    void main(){
        gl_Position = ftransform();
        texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    }
#endif

#ifdef FRAGMENT
    uniform sampler2D BUFFER_VIEW;

    /* Texture buffer  settings */

    /*
    const int gcolorFormat = R11F_G11F_B10F;
    const int colortex1Format = RGB16;
    const int colortex2Format = RGB8;
    const int colortex3Format = RGB8;
    const int colortex4Format = RGB8_A2;
    const int colortex5Format = RGB10_A2;
    const int colortex6Format = RGBA16F;
    const int colortex7Format = RGBA8;
    */

    void main(){
        gl_FragColor = vec4(texture2D(BUFFER_VIEW, texcoord).rgb, 1); //final color
    }
#endif