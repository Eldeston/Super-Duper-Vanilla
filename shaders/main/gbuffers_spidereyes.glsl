#include "/lib/util.glsl"
#include "/lib/structs.glsl"
#include "/lib/settings.glsl"
#include "/lib/globalVar.glsl"

#include "/lib/globalSamplers.glsl"

INOUT vec2 texcoord;
INOUT vec4 glcolor;

#ifdef VERTEX
    void main() {
        gl_Position = ftransform();
        texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
        glcolor = gl_Color;
    }
#endif

#ifdef FRAGMENT
    uniform sampler2D texture;

    void main(){
        vec4 color = texture2D(texture, texcoord);
        color.rgb *= glcolor.rgb;

        if(color.a < 0.01) discard;

    /* DRAWBUFFERS:0234 */
        gl_FragData[0] = color; //gcolor
        gl_FragData[1] = vec4(0, 0, 0, 1); //colortex2
        gl_FragData[2] = vec4(0, 1, 0, 1); //colortex3
        gl_FragData[3] = vec4(glcolor.a, 0, color.a, 1); //colortex4
    }
#endif