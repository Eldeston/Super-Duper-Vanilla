#include "/lib/utility/util.glsl"
#include "/lib/structs.glsl"
#include "/lib/settings.glsl"

#include "/lib/globalVars/constants.glsl"
#include "/lib/globalVars/texUniforms.glsl"

INOUT vec2 texcoord;

#ifdef VERTEX
    void main(){
        gl_Position = ftransform();
        texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    }
#endif

#ifdef FRAGMENT
    /* Texture buffer  settings */

    /*
    const int gcolorFormat = RGB16F;
    const int colortex1Format = RGB16;
    const int colortex2Format = RGB8;
    const int colortex3Format = RGB8;
    const int colortex4Format = RGB2;
    const int colortex5Format = RGB16;
    const int colortex6Format = RGBA16F;
    */

    void main(){
        vec3 color = texture2D(BUFFER_VIEW, texcoord).rgb;

        gl_FragColor = vec4(pow(color, vec3(1.0 / GAMMA)), 1); //final color
    }
#endif