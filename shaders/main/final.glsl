#include "/lib/util.glsl"
#include "/lib/settings.glsl"
#include "/lib/globalVar.glsl"

#include "/lib/post/tonemap.glsl"

INOUT vec2 texcoord;

#ifdef VERTEX
    void main(){
        gl_Position = ftransform();
        texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    }
#endif

#ifdef FRAGMENT
    uniform sampler2D gcolor;
    uniform sampler2D colortex3;

    void main(){
        vec3 color = texture2D(gcolor, texcoord).rgb;

        color = toneA(color);

        #ifdef VIGNETTE
            // Apply vignette
            color *= pow(max(1.0 - length(texCoord - 0.5), 0.0), VIGNETTE_INTENSITY);
        #endif

        // color = texture2D(colortex3, texcoord).rgb * 2.0 - 1.0;
        // color = vec3(texture2D(colortex4, texcoord).z == 1.0);
        // color = vec3(float(texture2D(depthtex0, texcoord).r != 1.0));

    /* DRAWBUFFERS:0 */
        gl_FragData[0] = vec4(color, 1.0); //gcolor
    }
#endif