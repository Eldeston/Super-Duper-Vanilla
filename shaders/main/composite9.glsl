/*
================================ /// Super Duper Vanilla v1.3.9 /// ================================

    Developed by Eldeston, presented by FlameRender (C) Studios.

    Copyright (C) 2025 Eldeston | FlameRender (C) Studios License


    By downloading this content you have agreed to the license and its terms of use.

================================ /// Super Duper Vanilla v1.3.9 /// ================================
*/

/// Buffer features: Lens flare, applied bloom, auto exposure, tonemapping, vignette and postColOut grading

/// -------------------------------- /// Vertex Shader /// -------------------------------- ///

#ifdef VERTEX
    #ifdef VIGNETTE
        noperspective out vec2 texCoord;
    #endif

    void main(){
        #ifdef VIGNETTE
            texCoord = gl_MultiTexCoord0.xy;
        #endif

        gl_Position = vec4(gl_Vertex.xy * 2.0 - 1.0, 0, 1);
    }
#endif

/// -------------------------------- /// Fragment Shader /// -------------------------------- ///

#ifdef FRAGMENT
    /* RENDERTARGETS: 3 */
    layout(location = 0) out vec3 postColOut; // colortex3

    #ifdef AUTO_EXPOSURE
        /* RENDERTARGETS: 3,5 */
        layout(location = 1) out vec4 temporalDataOut; // colortex5
    #endif

    #ifdef VIGNETTE
        noperspective in vec2 texCoord;
    #endif

    uniform sampler2D colortex4;

    #if defined LENS_FLARE && defined WORLD_LIGHT || defined BLOOM
        uniform sampler2D colortex0;
    #endif

    #ifdef AUTO_EXPOSURE
        uniform float frameTime;

        uniform sampler2D colortex5;
    #endif

    #include "/lib/utility/noiseFunctions.glsl"

    #include "/lib/post/tonemap.glsl"

    void main(){
        // Screen texel coordinates
        ivec2 screenTexelCoord = ivec2(gl_FragCoord.xy);

        // Get scene color
        postColOut = texelFetch(colortex4, screenTexelCoord, 0).rgb;

        #if defined LENS_FLARE && defined WORLD_LIGHT || defined BLOOM
            // Uncompress the HDR colors and upscale
            vec3 bloomCol = texelFetch(colortex0, ivec2(gl_FragCoord.xy * 0.5), 0).rgb;
            postColOut += bloomCol;
        #endif

        #ifdef AUTO_EXPOSURE
            // Get center pixel current average scene luminance and mix previous and current pixel...
            float centerPixLuminance = sumOf(textureLod(colortex4, vec2(0.5), 8).rgb);

            // Accumulate current luminance
            float frameTimeExposure = AUTO_EXPOSURE_SPEED * frameTime;
            float tempPixLuminance = mix(texelFetch(colortex5, ivec2(1), 0).a, centerPixLuminance, frameTimeExposure / (1.0 + frameTimeExposure));

            // Apply auto exposure by dividing it by the pixel's luminance in sRGB
            const float invMinimumExposure = 1.0 / MINIMUM_EXPOSURE;
            postColOut *= min(inversesqrt(tempPixLuminance), invMinimumExposure);

            #if (defined PREVIOUS_FRAME && (defined SSR || defined SSGI)) || ANTI_ALIASING >= 2
                temporalDataOut = vec4(texelFetch(colortex5, screenTexelCoord, 0).rgb, tempPixLuminance);
            #else
                temporalDataOut = vec4(0, 0, 0, tempPixLuminance);
            #endif
        #endif

        #ifdef VIGNETTE
            postColOut *= max(0.0, 1.0 - lengthSquared(texCoord - 0.5) * VIGNETTE_STRENGTH);
        #endif

        // Color tinting, exposure, and tonemapping
        const vec3 exposureTint = vec3(TINT_R, TINT_G, TINT_B) * (EXPOSURE * 0.00392156863);
        postColOut = modifiedReinhardJodieExtended(postColOut * exposureTint);

        // Gamma correction
        postColOut = toSRGB(postColOut);

        // Contrast and saturation
        postColOut = contrast(postColOut, CONTRAST);
        postColOut = saturation(postColOut, SATURATION);

        // Apply dithering to break postColOut banding
        postColOut += (texelFetch(noisetex, screenTexelCoord & 255, 0).x - 0.5) * 0.00392156863;
    }
#endif