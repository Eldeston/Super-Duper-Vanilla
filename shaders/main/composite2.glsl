#include "/lib/util.glsl"
#include "/lib/structs.glsl"
#include "/lib/settings.glsl"
#include "/lib/globalVar.glsl"

#include "/lib/globalSamplers.glsl"

INOUT vec2 texcoord;

#ifdef VERTEX
    void main(){
        gl_Position = ftransform();
        texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    }
#endif

#ifdef FRAGMENT
    void main(){
        vec3 color = texture2D(gcolor, texcoord).rgb;
        
        /*
        vec3 prevColor = texture2D(colortex7, texcoord).rgb;
        vec3 accumilate = mix(color, prevColor, exp2(-32.0 * frameTime));
        */

    /* DRAWBUFFERS:0 */
        gl_FragData[0] = vec4(color, 1); //gcolor
        // gl_FragData[1] = vec4(accumilate, 1); //colortex7
    }
#endif