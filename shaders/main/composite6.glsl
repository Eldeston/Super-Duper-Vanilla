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
    #if AUTO_EXPOSURE == 2
        const bool gcolorMipmapEnabled = true;
        const bool colortex6MipmapEnabled = true;
        const bool colortex6Clear = false;
    #endif

    uniform sampler2D gcolor;

    // Get frame time
    uniform float frameTime;

    uniform int isEyeInWater;

    uniform float nightVision;
    uniform float rainStrength;

    uniform ivec2 eyeBrightnessSmooth;

    #if AUTO_EXPOSURE == 2
        uniform sampler2D colortex6;
    #endif

    #if AUTO_EXPOSURE == 1
        // Get world time
        uniform float day;
        uniform float dawnDusk;
        uniform float twilight;

        uniform vec3 fogColor;

        #include "/lib/universalVars.glsl"
    #endif

    #include "/lib/post/tonemap.glsl"

    void main(){
        // Original scene color
        vec3 color = texture2D(gcolor, texcoord).rgb;

        #if AUTO_EXPOSURE == 2
            // Get current average scene luminance...
            // Center pixel
            float lumiCurrent = getLuminance(texture2D(gcolor, vec2(0.5), 10.0).rgb);
            // Left pixel
            lumiCurrent += getLuminance(texture2D(gcolor, vec2(0, 0.5), 10.0).rgb);
            // Right pixel
            lumiCurrent += getLuminance(texture2D(gcolor, vec2(1, 0.5), 10.0).rgb);

            // Mix previous and current buffer...
            float accumulatedLumi = mix(lumiCurrent * 0.333, texture2D(colortex6, vec2(0)).a, exp2(-1.0 * frameTime));

            // Apply exposure
            color /= max(accumulatedLumi * AUTO_EXPOSURE_MULT, MIN_EXPOSURE_DENOM);
        #elif AUTO_EXPOSURE == 1
            float accumulatedLumi = 1.0;
            // Recreate our lighting model if it were only shading a single pixel and apply exposure
            #if defined ENABLE_LIGHT
                color /= max(getLuminance(((torchBrightFact * (BLOCKLIGHT_I * 0.00392156863)) * vec3(BLOCKLIGHT_R, BLOCKLIGHT_G, BLOCKLIGHT_B) + eyeBrightFact * float(isEyeInWater != 1) * (lightCol * rainMult + skyCol) + ambientLighting) * 0.32) * AUTO_EXPOSURE_MULT, MIN_EXPOSURE_DENOM);
            #else
                color /= max(getLuminance(((torchBrightFact * (BLOCKLIGHT_I * 0.00392156863)) * vec3(BLOCKLIGHT_R, BLOCKLIGHT_G, BLOCKLIGHT_B) + eyeBrightFact * float(isEyeInWater != 1) * skyCol + ambientLighting) * 0.32) * AUTO_EXPOSURE_MULT, MIN_EXPOSURE_DENOM);
            #endif
        #else
            float accumulatedLumi = 1.0;
            color /= max(accumulatedLumi * AUTO_EXPOSURE_MULT, MIN_EXPOSURE_DENOM);
        #endif

        // Exposeure, tint, and tonemap
        color = whitePreservingLumaBasedReinhardToneMapping(color * vec3(TINT_R, TINT_G, TINT_B) * EXPOSURE);

        #ifdef VIGNETTE
            // BSL's vignette, modified to control intensity
            color *= max(0.0, 1.0 - length(texcoord - 0.5) * VIGNETTE_INTENSITY * (1.0 - getLuminance(color)));
        #endif

        // Gamma correction
        color = pow(color, vec3(1.0 / 2.2));
        
        // Color saturation, contrast, etc.
        color = toneA(color);

    /* DRAWBUFFERS:0 */
        gl_FragData[0] = vec4(color, 1); //gcolor

        #if AUTO_EXPOSURE == 2
        /* DRAWBUFFERS:06 */
            gl_FragData[1] = vec4(0, 0, 0, max(0.001, accumulatedLumi)); //colortex6
        #endif
    }
#endif