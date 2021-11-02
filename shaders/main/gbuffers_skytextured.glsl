#include "/lib/utility/util.glsl"
#include "/lib/settings.glsl"

INOUT vec2 texcoord;

#ifdef VERTEX
    void main() {
        gl_Position = ftransform();
        texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    }
#endif

#ifdef FRAGMENT
    #ifdef VANILLA_SUN_MOON
        uniform sampler2D texture;
    #endif
    
    void main(){
        #ifdef VANILLA_SUN_MOON
            vec4 color = texture2D(texture, texcoord);

        /* DRAWBUFFERS:2 */
            gl_FragData[0] = color; //colortex2
        #else
        /* DRAWBUFFERS:2 */
            gl_FragData[0] = vec4(0); //colortex2
        #endif
    }
#endif