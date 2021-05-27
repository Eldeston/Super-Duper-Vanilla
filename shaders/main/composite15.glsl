#include "/lib/util.glsl"
#include "/lib/settings.glsl"
#include "/lib/globalVar.glsl"

#include "/lib/globalSamplers.glsl"

#include "/lib/post/tonemap.glsl"

INOUT vec2 texcoord;

#ifdef VERTEX
    void main(){
        gl_Position = ftransform();
        texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    }
#endif

#ifdef FRAGMENT
    void main(){
        vec3 color = texture2D(colortex8, texcoord).rgb;
        color = toneA(color);

        #ifdef VIGNETTE
            // Apply vignette
            color *= pow(max(1.0 - length(texcoord - 0.5), 0.0), VIGNETTE_INTENSITY);
        #endif

    /* DRAWBUFFERS:8 */
        gl_FragData[0] = vec4(color, 1); //colortex8
    }
#endif