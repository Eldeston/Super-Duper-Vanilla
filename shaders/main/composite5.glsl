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

    // Get frame time
    uniform float frameTime;

    uniform int isEyeInWater;

    uniform float nightVision;
    uniform float rainStrength;

    uniform ivec2 eyeBrightnessSmooth;

    uniform sampler2D colortex6;

    #ifdef BLOOM
        uniform sampler2D colortex2;

        vec3 getBloomTile(vec2 uv, vec2 coords, float LOD){
            // Uncompress bloom
            return texture2D(colortex2, uv / exp2(LOD) + coords).rgb;
        }
    #endif

    #include "/lib/post/tonemap.glsl"

    void main(){
        // Original scene color
        vec3 color = texture2D(gcolor, texcoord).rgb;

        #ifdef BLOOM
            // Uncompress the HDR colors and upscale
            vec3 eBloom = getBloomTile(texcoord, vec2(0), 2.0);
            eBloom += getBloomTile(texcoord, vec2(0, 0.26), 3.0);
            eBloom += getBloomTile(texcoord, vec2(0.135, 0.26), 4.0);
            eBloom += getBloomTile(texcoord, vec2(0.2075, 0.26), 5.0);
            eBloom += getBloomTile(texcoord, vec2(0.135, 0.3325), 6.0);
            eBloom += getBloomTile(texcoord, vec2(0.160625, 0.3325), 7.0);
            eBloom = 1.0 / (1.0 - eBloom * 0.167) - 1.0;

            color = mix(color, eBloom, 0.2 * BLOOM_BRIGHTNESS);
        #endif

        #ifdef AUTO_EXPOSURE
            // Get current average scene luminance...
            // Center pixel
            float lumiCurrent = length(texture2D(gcolor, vec2(0.5), 10.0).rgb);

            // Mix previous and current buffer...
            float tempPixelLuminance = mix(sqrt(lumiCurrent), texture2D(colortex6, vec2(0)).a, exp2(-1.0 * frameTime));

            // Apply auto exposure
            color /= tempPixelLuminance;
        #else
            float tempPixelLuminance = 0.0;
        #endif

        // Exposeure, tint, and tonemap
        color = whitePreservingLumaBasedReinhardToneMapping(color * vec3(TINT_R, TINT_G, TINT_B) * (0.00392156863 * EXPOSURE));

        #ifdef VIGNETTE
            // BSL's vignette, modified to control intensity
            color *= max(0.0, 1.0 - length(texcoord - 0.5) * VIGNETTE_INTENSITY * (1.0 - getLuminance(color)));
        #endif

        // Gamma correction
        color = pow(color, vec3(RCPGAMMA));
        
        // Color saturation, contrast, etc.
        color = toneA(color);

    /* DRAWBUFFERS:0 */
        gl_FragData[0] = vec4(color, 1); //gcolor

        #ifdef BLOOM
        /* DRAWBUFFERS:02 */
            gl_FragData[1] = vec4(eBloom, 1); //colortex2

            #if ANTI_ALIASING == 2
            /* DRAWBUFFERS:026 */
                gl_FragData[2] = vec4(texture2D(colortex6, texcoord).rgb, tempPixelLuminance); //colortex6
            #endif
        #else
            #if ANTI_ALIASING == 2
            /* DRAWBUFFERS:06 */
                gl_FragData[1] = vec4(texture2D(colortex6, texcoord).rgb, tempPixelLuminance); //colortex6
            #endif
        #endif
    }
#endif