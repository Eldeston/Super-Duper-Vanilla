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
    uniform sampler2D gcolor;

    #if BLOOM != 0
        uniform sampler2D colortex2;

        vec3 getBloomTile(vec2 uv, vec2 coords, float LOD){
            // Uncompress bloom
            return texture2D(colortex2, uv / exp2(LOD) + coords).rgb;
        }
    #endif

    void main(){
        // Original scene color
        vec3 color = texture2D(gcolor, texcoord).rgb;

        #if BLOOM != 0
            // Uncompress the HDR colors and upscale
            vec3 eBloom = getBloomTile(texcoord, vec2(0), 2.0);
            eBloom += getBloomTile(texcoord, vec2(0, 0.26), 3.0);
            eBloom += getBloomTile(texcoord, vec2(0.135, 0.26), 4.0);
            eBloom += getBloomTile(texcoord, vec2(0.2075, 0.26), 5.0);
            eBloom += getBloomTile(texcoord, vec2(0.135, 0.3325), 6.0);
            eBloom += getBloomTile(texcoord, vec2(0.160625, 0.3325), 7.0);
            eBloom = (1.0 / (1.0 - eBloom * 0.167) - 1.0) * BLOOM_BRIGHTNESS;

            #if BLOOM == 1
                color += eBloom;
            #elif BLOOM == 2
                color = mix(color, eBloom, 0.2);
            #endif
        #endif

    /* DRAWBUFFERS:0 */
        gl_FragData[0] = vec4(color, 1); //gcolor

        #if BLOOM != 0
            /* DRAWBUFFERS:02 */
                gl_FragData[1] = vec4(eBloom, 1); //colortex2
        #endif
    }
#endif