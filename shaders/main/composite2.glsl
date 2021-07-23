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

        uniform float viewWidth;

        vec3 bloomTile(vec2 uv, vec2 coords, float LOD){
            float scale = exp2(LOD);
            vec2 pixelSize = vec2(scale / viewWidth, 0);
            vec2 bloomUv = (uv - coords) * scale;
            float padding = 0.5 + 0.005 * scale;

            vec3 eBloom = vec3(0);
            if(abs(bloomUv.x - 0.5) < padding && abs(bloomUv.y - 0.5) < padding){
                eBloom += texture2D(colortex2, bloomUv + pixelSize * 2.0).rgb * 0.0625;
                eBloom += texture2D(colortex2, bloomUv + pixelSize).rgb * 0.25;
                eBloom += texture2D(colortex2, bloomUv).rgb * 0.375;
                eBloom += texture2D(colortex2, bloomUv - pixelSize).rgb * 0.25;
                eBloom += texture2D(colortex2, bloomUv - pixelSize * 2.0).rgb * 0.0625;
            }
            
            return eBloom;
        }
    #endif

    void main(){
        #ifdef BLOOM
            vec3 eBloom = bloomTile(texcoord, vec2(0), 2.0 * BLOOM_LOD);
            eBloom += bloomTile(texcoord, vec2(0, 0.26), 3.0 * BLOOM_LOD);
            eBloom += bloomTile(texcoord, vec2(0.135, 0.26), 4.0 * BLOOM_LOD);
            eBloom += bloomTile(texcoord, vec2(0.2075, 0.26), 5.0 * BLOOM_LOD);
            eBloom += bloomTile(texcoord, vec2(0.135, 0.3325), 6.0 * BLOOM_LOD);
            eBloom += bloomTile(texcoord, vec2(0.160625, 0.3325), 7.0 * BLOOM_LOD);
        #else
            vec3 eBloom = vec3(0);
        #endif

        /* DRAWBUFFERS:2 */
            gl_FragData[0] = vec4(eBloom, 1); //colortex2
    }
#endif