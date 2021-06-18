#include "/lib/utility/util.glsl"
#include "/lib/structs.glsl"
#include "/lib/settings.glsl"

#include "/lib/globalVars/constants.glsl"

// Vanilla AO
INOUT float glalpha;

INOUT vec2 texcoord;

INOUT vec3 norm;

#ifdef VERTEX
    void main(){
        gl_Position = ftransform();

        texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

        norm = normalize(gl_NormalMatrix * gl_Normal);

        glalpha = gl_Color.a;
    }
#endif

#ifdef FRAGMENT
    uniform sampler2D texture;

    void main(){
        #ifdef SHADER_CLOUDS
        /* DRAWBUFFERS:0 */
            gl_FragData[0] = vec4(0); //gcolor
        #else
            vec4 color = texture2D(texture, texcoord);
        /* DRAWBUFFERS:01234 */
            gl_FragData[0] = color; //gcolor
            gl_FragData[1] = vec4(norm * 0.5 + 0.5, 1); //colortex1
            gl_FragData[2] = vec4(0, 1, 0.72, 1); //colortex2
            gl_FragData[3] = vec4(0, 0, 1, 1); //colortex3
            gl_FragData[4] = vec4(glalpha, 1, 0, 1); //colortex4
        #endif
    }
#endif