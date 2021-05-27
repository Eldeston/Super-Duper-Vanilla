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
        #ifdef BLOOM
            vec3 color = texture2D(colortex8, texcoord).rgb;
            
            float pixelSize = (BLOOM_PIX_SIZE * 2.0) / min(viewWidth, viewHeight);
            vec3 eBloom = vec3(0);
            #if BLOOM_QUALITY == 0
                eBloom += texture2D(colortex7, texcoord, BLOOM_LOD).rgb;
            #elif BLOOM_QUALITY == 1
                eBloom += texture2D(colortex7, texcoord + vec2(0, pixelSize) * 1.2, BLOOM_LOD).rgb * 0.25;
                eBloom += texture2D(colortex7, texcoord, int(sqrt(BLOOM_LOD))).rgb * 0.5;
                eBloom += texture2D(colortex7, texcoord - vec2(0, pixelSize) * 1.2, BLOOM_LOD).rgb * 0.25;
            #elif BLOOM_QUALITY == 2
                eBloom += texture2D(colortex7, texcoord + vec2(0, pixelSize) * 1.8, BLOOM_LOD).rgb * 0.0625;
                eBloom += texture2D(colortex7, texcoord + vec2(0, pixelSize), BLOOM_LOD).rgb * 0.25;
                eBloom += texture2D(colortex7, texcoord, int(sqrt(BLOOM_LOD))).rgb * 0.375;
                eBloom += texture2D(colortex7, texcoord - vec2(0, pixelSize), BLOOM_LOD).rgb * 0.25;
                eBloom += texture2D(colortex7, texcoord - vec2(0, pixelSize) * 1.8, BLOOM_LOD).rgb * 0.0625;
            #elif BLOOM_QUALITY == 3
                eBloom += texture2D(colortex7, texcoord + vec2(0, pixelSize) * 2.0, BLOOM_LOD).rgb * 0.015625;
                eBloom += texture2D(colortex7, texcoord + vec2(0, pixelSize) * 1.8, BLOOM_LOD).rgb * 0.09375;
                eBloom += texture2D(colortex7, texcoord + vec2(0, pixelSize), BLOOM_LOD).rgb * 0.234375;
                eBloom += texture2D(colortex7, texcoord, int(sqrt(BLOOM_LOD))).rgb * 0.3125;
                eBloom += texture2D(colortex7, texcoord - vec2(0, pixelSize), BLOOM_LOD).rgb * 0.234375;
                eBloom += texture2D(colortex7, texcoord - vec2(0, pixelSize) * 1.8, BLOOM_LOD).rgb * 0.09375;
                eBloom += texture2D(colortex7, texcoord + vec2(0, pixelSize) * 2.0, BLOOM_LOD).rgb * 0.015625;
            #endif
        /* DRAWBUFFERS:78 */
            gl_FragData[0] = vec4(eBloom, 1); //colortex7
            gl_FragData[1] = vec4(color + eBloom, 1); //colortex8
        #endif
    }
#endif