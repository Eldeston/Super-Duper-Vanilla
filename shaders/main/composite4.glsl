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
        vec3 color = texture2D(gcolor, texcoord).rgb;

        #ifdef BLOOM
            // Uncompress the HDR colors
            vec3 eBloom = (1.0 / (1.0 - texture2D(colortex2, texcoord * 0.25).rgb) - 1.0) * BLOOM_BRIGHTNESS;
            color += eBloom;
        #endif

    /* DRAWBUFFERS:0 */
        gl_FragData[0] = vec4(color, 1); //gcolor

        #ifdef BLOOM
        /* DRAWBUFFERS:02 */
            gl_FragData[1] = vec4(eBloom, 1); //colortex2
        #endif
    }
#endif