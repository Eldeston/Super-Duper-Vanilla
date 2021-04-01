#include "/lib/util.glsl"
#include "/lib/settings.glsl"
#include "/lib/globalVar.glsl"

#include "/lib/tonemap.glsl"

INOUT vec2 texcoord;

#ifdef VERTEX
    void main() {
        gl_Position = ftransform();
        texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    }
#endif

#ifdef FRAGMENT
    uniform sampler2D gcolor;
    uniform sampler2D depthtex0;

    void main() {
        vec3 color = texture2D(gcolor, texcoord).rgb;

        color = toneA(color);

        // color = texture2D(colortex1, texcoord).rgb * 2.0 - 1.0;
        // color = vec3(texture2D(colortex4, texcoord).z == 1.0);
        // color = vec3(float(texture2D(depthtex0, texcoord).r != 1.0));

    /* DRAWBUFFERS:0 */
        gl_FragData[0] = vec4(color, 1.0); //gcolor
    }
#endif