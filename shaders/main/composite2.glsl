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
    const bool colortex2MipmapEnabled = true;
    
    uniform sampler2D colortex2;

    uniform float viewWidth;

    void main(){
        #ifdef BLOOM
            float pixelSize = BLOOM_PIX_SIZE / viewWidth;
            vec3 eBloom = vec3(0);
            #if BLOOM_QUALITY == 0
                eBloom += texture2D(colortex2, texcoord, 0.5).rgb;
            #elif BLOOM_QUALITY == 1
                eBloom += texture2D(colortex2, texcoord + vec2(pixelSize, 0) * 1.2, BLOOM_LOD).rgb * 0.25;
                eBloom += texture2D(colortex2, texcoord, int(sqrt(BLOOM_LOD))).rgb * 0.5;
                eBloom += texture2D(colortex2, texcoord - vec2(pixelSize, 0) * 1.2, BLOOM_LOD).rgb * 0.25;
            #elif BLOOM_QUALITY == 2
                eBloom += texture2D(colortex2, texcoord + vec2(pixelSize, 0) * 2.4, 2.0 * BLOOM_LOD).rgb * 0.0625;
                eBloom += texture2D(colortex2, texcoord + vec2(pixelSize, 0) * 1.2, BLOOM_LOD).rgb * 0.25;
                eBloom += texture2D(colortex2, texcoord, int(sqrt(BLOOM_LOD))).rgb * 0.375;
                eBloom += texture2D(colortex2, texcoord - vec2(pixelSize, 0) * 1.2, BLOOM_LOD).rgb * 0.25;
                eBloom += texture2D(colortex2, texcoord - vec2(pixelSize, 0) * 2.4, 2.0 * BLOOM_LOD).rgb * 0.0625;
            #elif BLOOM_QUALITY == 3
                eBloom += texture2D(colortex2, texcoord + vec2(pixelSize, 0) * 3.6, 3.0 * BLOOM_LOD).rgb * 0.015625;
                eBloom += texture2D(colortex2, texcoord + vec2(pixelSize, 0) * 2.4, 2.0 * BLOOM_LOD).rgb * 0.09375;
                eBloom += texture2D(colortex2, texcoord + vec2(pixelSize, 0) * 1.2, BLOOM_LOD).rgb * 0.234375;
                eBloom += texture2D(colortex2, texcoord, int(sqrt(BLOOM_LOD))).rgb * 0.3125;
                eBloom += texture2D(colortex2, texcoord - vec2(pixelSize, 0) * 1.2, BLOOM_LOD).rgb * 0.234375;
                eBloom += texture2D(colortex2, texcoord - vec2(pixelSize, 0) * 2.4, 2.0 * BLOOM_LOD).rgb * 0.09375;
                eBloom += texture2D(colortex2, texcoord + vec2(pixelSize, 0) * 3.6, 3.0 * BLOOM_LOD).rgb * 0.015625;
            #endif

        /* DRAWBUFFERS:2 */
            gl_FragData[0] = vec4(eBloom, 1); //colortex2
        #endif
    }
#endif