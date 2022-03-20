#include "/lib/utility/util.glsl"
#include "/lib/settings.glsl"

varying vec2 texCoord;

#ifdef VERTEX
    void main(){
        gl_Position = ftransform();
        texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    }
#endif

#ifdef FRAGMENT
    #ifdef BLOOM
        const bool gcolorMipmapEnabled = true;
        
        uniform sampler2D gcolor;

        uniform float viewWidth;

        vec3 bloomTile(vec2 uv, vec2 coords, float LOD){
            float scale = exp2(LOD);
            float pixelSize = scale / viewWidth;
            vec2 bloomUv = (uv - coords) * scale;
            float padding = 0.5 + 0.005 * scale;

            if(abs(bloomUv.x - 0.5) < padding && abs(bloomUv.y - 0.5) < padding){
                vec3 eBloom = texture2D(gcolor, bloomUv + vec2(pixelSize * 2.0, 0)).rgb * 0.0625;
                eBloom += texture2D(gcolor, bloomUv + vec2(pixelSize, 0)).rgb * 0.25;
                eBloom += texture2D(gcolor, bloomUv).rgb * 0.375;
                eBloom += texture2D(gcolor, bloomUv - vec2(pixelSize, 0)).rgb * 0.25;
                return eBloom + texture2D(gcolor, bloomUv - vec2(pixelSize * 2.0, 0)).rgb * 0.0625;
            }
            
            return vec3(0);
        }
    #endif

    void main(){
        #ifdef BLOOM
            vec3 eBloom = bloomTile(texCoord, vec2(0), 2.0);
            eBloom += bloomTile(texCoord, vec2(0, 0.275), 3.0);
            eBloom += bloomTile(texCoord, vec2(0.135, 0.275), 4.0);
            eBloom += bloomTile(texCoord, vec2(0.2075, 0.275), 5.0);
            eBloom += bloomTile(texCoord, vec2(0.135, 0.3625), 6.0);
            eBloom += bloomTile(texCoord, vec2(0.160625, 0.3625), 7.0);
        
        /* DRAWBUFFERS:4 */
            gl_FragData[0] = vec4(eBloom, 1); //colortex4
        #else
        /* DRAWBUFFERS:4 */
            gl_FragData[0] = vec4(0, 0, 0, 1); //colortex4
        #endif
    }
#endif