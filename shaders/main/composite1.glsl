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
    void main(){
        vec3 color = texture2D(gcolor, texcoord).rgb * texture2D(colortex3, texcoord).g;

    /* DRAWBUFFERS:2 */
        // Compress the HDR colors
        gl_FragData[0] = vec4(color / (1.0 + color), 1); //colortex2
    }
#endif