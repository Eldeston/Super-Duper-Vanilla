#include "/lib/utility/util.glsl"
#include "/lib/structs.glsl"
#include "/lib/settings.glsl"

INOUT vec2 texcoord;

#ifdef VERTEX
    void main(){
        gl_Position = ftransform();
        texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    }
#endif

#ifdef FRAGMENT
    #ifdef BLOOM
        const bool colortex2MipmapEnabled = true;
        
        uniform sampler2D colortex2;

        uniform float viewHeight;
    #endif

    void main(){
        #if BLOOM != 0
            float pixelSize = 1.0 / viewHeight;
            vec3 eBloom = texture2D(colortex2, texcoord + vec2(0, pixelSize * 2.0)).rgb * 0.0625;
            eBloom += texture2D(colortex2, texcoord + vec2(0, pixelSize)).rgb * 0.25;
            eBloom += texture2D(colortex2, texcoord).rgb * 0.375;
            eBloom += texture2D(colortex2, texcoord + vec2(0, pixelSize)).rgb * 0.25;
            eBloom += texture2D(colortex2, texcoord + vec2(0, pixelSize * 2.0)).rgb * 0.0625;
        #else
            vec3 eBloom = texture2D(colortex2, texcoord).rgb;
        #endif

    /* DRAWBUFFERS:2 */
        gl_FragData[0] = vec4(eBloom, 1); //colortex2
    }
#endif