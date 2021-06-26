#include "/lib/utility/util.glsl"
#include "/lib/structs.glsl"
#include "/lib/settings.glsl"

#include "/lib/globalVars/constants.glsl"
#include "/lib/globalVars/screenUniforms.glsl"
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
    const int colortex4Format = RGB8;
    const int colortex5Format = RGB16;
    const int colortex6Format = RGBA16F;
    const int colortex7Format = RGB8;
    */

    void main(){
        #ifdef FXAA
            vec2 newTexCoord = floor(texcoord * vec2(viewWidth, viewHeight)) / vec2(viewWidth, viewHeight);
            vec3 color = texture2D(BUFFER_VIEW, newTexCoord).rgb;
        #else
            vec3 color = texture2D(BUFFER_VIEW, texcoord).rgb;
        #endif

        gl_FragColor = vec4(pow(color, vec3(1.0 / GAMMA)), 1); //final color
    }
#endif