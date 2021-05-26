#include "/lib/util.glsl"
#include "/lib/structs.glsl"
#include "/lib/settings.glsl"
#include "/lib/globalVar.glsl"

#include "/lib/globalSamplers.glsl"

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
            float pixelSize = (BLOOM_PIX_SIZE * 2.0) / min(viewWidth, viewHeight);
            vec3 eBloom = texture2D(colortex7, texcoord, int(sqrt(BLOOM_LOD))).rgb;
            eBloom += texture2D(colortex7, texcoord + vec2(0, pixelSize), BLOOM_LOD).rgb;
            eBloom += texture2D(colortex7, texcoord + vec2(0, pixelSize) * 1.8, BLOOM_LOD).rgb;
            eBloom += texture2D(colortex7, texcoord - vec2(0, pixelSize), BLOOM_LOD).rgb;
            eBloom += texture2D(colortex7, texcoord - vec2(0, pixelSize) * 1.8, BLOOM_LOD).rgb;
            if(BLOOM_QUALITY == 2){
                eBloom += texture2D(colortex7, texcoord + vec2(0, pixelSize) * 1.5, BLOOM_LOD).rgb;
                eBloom += texture2D(colortex7, texcoord + vec2(0, pixelSize) * 2.0, BLOOM_LOD).rgb;
                eBloom += texture2D(colortex7, texcoord - vec2(0, pixelSize) * 1.5, BLOOM_LOD).rgb;
                eBloom += texture2D(colortex7, texcoord - vec2(0, pixelSize) * 2.0, BLOOM_LOD).rgb;
                eBloom /= 9.0;
            } else {
                eBloom /= 5.0;
            }
            color += eBloom;
        #endif

    /* DRAWBUFFERS:0 */
        gl_FragData[0] = vec4(color, 1); //gcolor

        #ifdef BLOOM
        /* DRAWBUFFERS:07 */
            gl_FragData[1] = vec4(eBloom, 1); //colortex7
        #endif
    }
#endif