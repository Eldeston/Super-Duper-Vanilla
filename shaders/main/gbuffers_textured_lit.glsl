#include "/lib/util.glsl"
#include "/lib/structs.glsl"
#include "/lib/settings.glsl"
#include "/lib/globalVar.glsl"

#include "/lib/globalSamplers.glsl"

INOUT vec2 lmcoord;
INOUT vec2 texcoord;

INOUT vec3 norm;

INOUT vec4 glcolor;

INOUT mat3 TBN;

#ifdef VERTEX
    attribute vec2 mc_midTexCoord;

    attribute vec4 mc_Entity;
    attribute vec4 at_tangent;

    void main(){
	    gl_Position = ftransform();

        texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
        lmcoord  = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;

        vec3 tangent = normalize(gl_NormalMatrix * at_tangent.xyz);
	    vec3 binormal = normalize(gl_NormalMatrix * cross(at_tangent.xyz, gl_Normal) * sign(at_tangent.w));

	    norm = normalize(gl_NormalMatrix * gl_Normal);

	    TBN = mat3(tangent, binormal, norm);

        glcolor = gl_Color;
    }
#endif

#ifdef FRAGMENT
    uniform sampler2D lightmap;
    uniform sampler2D texture;

    void main(){
        vec4 color = texture2D(texture, texcoord);
        color.rgb *= glcolor.rgb;

        vec3 normal = mat3(gbufferModelViewInverse) * norm;

    /* DRAWBUFFERS:01234 */
        gl_FragData[0] = color; //gcolor
        gl_FragData[1] = vec4(normal * 0.5 + 0.5, 1); //colortex1
        gl_FragData[2] = vec4(lmcoord, 1, 1); //colortex2
        gl_FragData[3] = vec4(0, 1, 1, 1); //colortex3
        gl_FragData[4] = vec4(glcolor.a, 0, 0, 1); //colortex4
    }
#endif