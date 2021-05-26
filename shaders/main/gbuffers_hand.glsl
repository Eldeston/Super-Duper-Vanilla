#include "/lib/util.glsl"
#include "/lib/structs.glsl"
#include "/lib/settings.glsl"
#include "/lib/globalVar.glsl"

#include "/lib/globalSamplers.glsl"

INOUT vec2 lmcoord;
INOUT vec2 texcoord;

INOUT vec3 norm;

INOUT vec4 glcolor;

#ifdef VERTEX
    void main() {
        texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
        lmcoord  = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;

        norm = normalize(gl_NormalMatrix * gl_Normal);

        gl_Position = ftransform();

        glcolor = gl_Color;
    }
#endif

#ifdef FRAGMENT
    uniform sampler2D lightmap;
    uniform sampler2D texture;

    void main(){
	    vec4 color = texture2D(texture, texcoord);
        color.rgb *= glcolor.rgb;

	    color.rgb = mix(color.rgb, entityColor.rgb, entityColor.a);

    /* DRAWBUFFERS:01234 */
        gl_FragData[0] = color; //gcolor
        gl_FragData[1] = vec4(norm * 0.5 + 0.5, 1); //colortex1
        gl_FragData[2] = vec4(lmcoord, 0, 1); //colortex2
        gl_FragData[3] = vec4(0, 0, 1, 1); //colortex3
        gl_FragData[4] = vec4(glcolor.a, 0, 1, 1); //colortex4
    }
#endif