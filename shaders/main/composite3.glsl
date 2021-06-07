#include "/lib/utility/util.glsl"
#include "/lib/structs.glsl"
#include "/lib/settings.glsl"

#include "/lib/globalVars/constants.glsl"
#include "/lib/globalVars/texUniforms.glsl"
#include "/lib/globalVars/screenUniforms.glsl"

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
            // Rescale coords for the downscaled previous program
            vec2 scaledUv = texcoord * 0.5;
            float pixelSize = BLOOM_PIX_SIZE / min(viewWidth, viewHeight);
            vec3 eBloom = vec3(0);
            #if BLOOM_QUALITY == 0
                eBloom += texture2D(colortex7, scaledUv, BLOOM_LOD).rgb;
            #elif BLOOM_QUALITY == 1
                eBloom += texture2D(colortex7, scaledUv + vec2(0, pixelSize) * 1.2, BLOOM_LOD).rgb * 0.25;
                eBloom += texture2D(colortex7, scaledUv, int(sqrt(BLOOM_LOD))).rgb * 0.5;
                eBloom += texture2D(colortex7, scaledUv - vec2(0, pixelSize) * 1.2, BLOOM_LOD).rgb * 0.25;
            #elif BLOOM_QUALITY == 2
                eBloom += texture2D(colortex7, scaledUv + vec2(0, pixelSize) * 1.8, BLOOM_LOD).rgb * 0.0625;
                eBloom += texture2D(colortex7, scaledUv + vec2(0, pixelSize), BLOOM_LOD).rgb * 0.25;
                eBloom += texture2D(colortex7, scaledUv, int(sqrt(BLOOM_LOD))).rgb * 0.375;
                eBloom += texture2D(colortex7, scaledUv - vec2(0, pixelSize), BLOOM_LOD).rgb * 0.25;
                eBloom += texture2D(colortex7, scaledUv - vec2(0, pixelSize) * 1.8, BLOOM_LOD).rgb * 0.0625;
            #elif BLOOM_QUALITY == 3
                eBloom += texture2D(colortex7, scaledUv + vec2(0, pixelSize) * 2.0, BLOOM_LOD).rgb * 0.015625;
                eBloom += texture2D(colortex7, scaledUv + vec2(0, pixelSize) * 1.8, BLOOM_LOD).rgb * 0.09375;
                eBloom += texture2D(colortex7, scaledUv + vec2(0, pixelSize), BLOOM_LOD).rgb * 0.234375;
                eBloom += texture2D(colortex7, scaledUv, int(sqrt(BLOOM_LOD))).rgb * 0.3125;
                eBloom += texture2D(colortex7, scaledUv - vec2(0, pixelSize), BLOOM_LOD).rgb * 0.234375;
                eBloom += texture2D(colortex7, scaledUv - vec2(0, pixelSize) * 1.8, BLOOM_LOD).rgb * 0.09375;
                eBloom += texture2D(colortex7, scaledUv + vec2(0, pixelSize) * 2.0, BLOOM_LOD).rgb * 0.015625;
            #endif
        /* DRAWBUFFERS:7 */
            gl_FragData[0] = vec4(eBloom * BLOOM_BRIGHTNESS, 1); //colortex7
        #endif
    }
#endif