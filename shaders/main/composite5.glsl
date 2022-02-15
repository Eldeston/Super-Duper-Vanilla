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
    uniform sampler2D gcolor;

    // Get frame time
    uniform float frameTime;

    uniform int isEyeInWater;

    uniform float nightVision;
    uniform float rainStrength;

    uniform ivec2 eyeBrightnessSmooth;

    #if ANTI_ALIASING == 2 || defined AUTO_EXPOSURE
        // Needs to be true whenever auto exposure or TAA is on
        const bool colortex6MipmapEnabled = true;
        // Needs to be false whenever auto exposure or TAA is on
        const bool colortex6Clear = false;

        #ifdef AUTO_EXPOSURE
            uniform sampler2D colortex6;
        #endif
    #endif

    #ifdef BLOOM
        uniform sampler2D colortex2;

        uniform float viewWidth;
        uniform float viewHeight;

        #include "/lib/utility/texFunctions.glsl"

        vec3 getBloomTile(vec2 uv, vec2 coords, float LOD){
            // Uncompress bloom
            return texture2DBicubic(colortex2, uv / exp2(LOD) + coords, vec2(viewWidth, viewHeight)).rgb;
        }
    #endif

    #include "/lib/utility/noiseFunctions.glsl"

    #include "/lib/post/tonemap.glsl"

    void main(){
        // Original scene color
        vec3 color = texture2D(gcolor, texCoord).rgb;

        #ifdef BLOOM
            // Uncompress the HDR colors and upscale
            vec3 eBloom = getBloomTile(texCoord, vec2(0), 2.0);
            eBloom += getBloomTile(texCoord, vec2(0, 0.26), 3.0);
            eBloom += getBloomTile(texCoord, vec2(0.135, 0.26), 4.0);
            eBloom += getBloomTile(texCoord, vec2(0.2075, 0.26), 5.0);
            eBloom += getBloomTile(texCoord, vec2(0.135, 0.3325), 6.0);
            eBloom += getBloomTile(texCoord, vec2(0.160625, 0.3325), 7.0);
            eBloom = eBloom * 0.16666667;

            color = mix(color, eBloom, 0.2 * BLOOM_BRIGHTNESS);
        #endif

        #ifdef AUTO_EXPOSURE
            // Get center pixel current average scene luminance...
            float lumiCurrent = max(sqrt(length(texture2D(gcolor, vec2(0.5), 10.0).rgb)), 0.05);

            // Mix previous and current buffer...
            float tempPixelLuminance = mix(lumiCurrent, texture2D(colortex6, vec2(0)).a, exp2(-AUTO_EXPOSURE_SPEED * frameTime));

            // Apply auto exposure
            color /= max(tempPixelLuminance, 0.05);

            #if ANTI_ALIASING == 2
                #define TAA_DATA texture2D(colortex6, texCoord).rgb
            #else
                // vec4(0, 0, 0, tempPixelLuminance)
                #define TAA_DATA 0, 0, 0
            #endif
        #endif

        // Exposeure, tint, and tonemap
        color = whitePreservingLumaBasedReinhardToneMapping(color * vec3(TINT_R, TINT_G, TINT_B) * (0.00392156863 * EXPOSURE));

        #ifdef VIGNETTE
            // BSL's vignette, modified to control intensity
            color *= max(0.0, 1.0 - length(texCoord - 0.5) * VIGNETTE_INTENSITY * (1.0 - getLuminance(color)));
        #endif

        // Gamma correction
        color = pow(color, vec3(RCPGAMMA));
        
        // Color saturation, contrast, etc. and film grain
        color = toneA(color) + (getRand1(gl_FragCoord.xy * 0.03125) - 0.5) * 0.00392156863;

    /* DRAWBUFFERS:0 */
        gl_FragData[0] = vec4(color, 1); //gcolor

        #ifdef BLOOM
        /* DRAWBUFFERS:02 */
            gl_FragData[1] = vec4(eBloom, 1); //colortex2

            #ifdef AUTO_EXPOSURE
            /* DRAWBUFFERS:026 */
                gl_FragData[2] = vec4(TAA_DATA, tempPixelLuminance); //colortex6
            #endif
        #else
            #ifdef AUTO_EXPOSURE
            /* DRAWBUFFERS:06 */
                gl_FragData[1] = vec4(TAA_DATA, tempPixelLuminance); //colortex6
            #endif
        #endif
    }
#endif