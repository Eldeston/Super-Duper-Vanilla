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
            vec2 pixelSize = vec2(0, 2.0 / viewHeight);
            // Skip the 2nd and 4th samples and instead do 3 samples as mipmaps will cover them for us 
            vec3 eBloom = texture2D(colortex2, texcoord + pixelSize).rgb * 0.25;
            eBloom += texture2D(colortex2, texcoord).rgb * 0.5;
            eBloom += texture2D(colortex2, texcoord + pixelSize).rgb * 0.25;
        #else
            vec3 eBloom = vec3(0);
        #endif

        /* DRAWBUFFERS:2 */
            gl_FragData[0] = vec4(eBloom, 1); //colortex2
    }
#endif