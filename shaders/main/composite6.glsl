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

    #include "/lib/post/tonemap.glsl"

    void main(){
        // Original scene color
        vec3 color = texture2D(gcolor, texcoord).rgb;

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
    }
#endif