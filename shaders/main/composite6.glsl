/*
================================ /// Super Duper Vanilla v1.3.3 /// ================================

    Developed by Eldeston, presented by FlameRender (TM) Studios.

    Copyright (C) 2020 Eldeston | FlameRender (TM) Studios License


    By downloading this content you have agreed to the license and its terms of use.

================================ /// Super Duper Vanilla v1.3.3 /// ================================
*/

/// Buffer features: Lens flare, applied bloom, auto exposure, tonemapping, vignette and color grading

/// -------------------------------- /// Vertex Shader /// -------------------------------- ///

#ifdef VERTEX
    #if defined LENS_FLARE && defined WORLD_LIGHT
        flat out vec3 sRGBLightCol;
        flat out vec3 shdLightDirScreenSpace;
    #endif

    out vec2 texCoord;

    #if defined LENS_FLARE && defined WORLD_LIGHT
        uniform mat4 gbufferProjection;

        uniform mat4 gbufferModelView;

        uniform mat4 shadowModelView;

        #ifndef FORCE_DISABLE_WEATHER
            uniform float rainStrength;
        #endif

        #ifndef FORCE_DISABLE_DAY_CYCLE
            uniform float dayCycle;
            uniform float twilightPhase;
        #endif

        #include "/lib/utility/convertScreenSpace.glsl"
    #endif

    void main(){
        texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

        #if defined LENS_FLARE && defined WORLD_LIGHT
            // Get sRGB light color
            sRGBLightCol = LIGHT_COL_DATA_BLOCK0;

            // Get shadow light view direction in screen space
            shdLightDirScreenSpace = vec3(toScreen(mat3(gbufferModelView) * vec3(shadowModelView[0].z, shadowModelView[1].z, shadowModelView[2].z)).xy, gbufferProjection[1].y * 0.72794047);
        #endif

        gl_Position = ftransform();
    }
#endif

/// -------------------------------- /// Fragment Shader /// -------------------------------- ///

#ifdef FRAGMENT
    #if defined LENS_FLARE && defined WORLD_LIGHT
        flat in vec3 sRGBLightCol;
        flat in vec3 shdLightDirScreenSpace;
    #endif

    in vec2 texCoord;

    uniform sampler2D gcolor;

    #ifdef LENS_FLARE
    #endif

    #ifdef AUTO_EXPOSURE
        uniform sampler2D colortex5;

        uniform float frameTime;
    #endif

    #ifdef BLOOM
        uniform sampler2D colortex4;

        uniform float viewWidth;
        uniform float viewHeight;

        vec3 getBloomTile(in vec2 pixSize, in vec2 coords, in float LOD){
            // Remap to bloom tile texture coordinates
            vec2 texCoord = texCoord / exp2(LOD) + coords;

            vec2 topRightCorner = texCoord + pixSize;
            vec2 bottomLeftCorner = texCoord - pixSize;

            // Apply box blur all tiles
            return textureLod(colortex4, bottomLeftCorner, 0).rgb + textureLod(colortex4, topRightCorner, 0).rgb +
                textureLod(colortex4, vec2(bottomLeftCorner.x, topRightCorner.y), 0).rgb + textureLod(colortex4, vec2(topRightCorner.x, bottomLeftCorner.y), 0).rgb;
        }
    #endif

    #if defined LENS_FLARE && defined WORLD_LIGHT
        uniform sampler2D depthtex0;

        // Get blindess
        uniform float blindness;
        // Get darkness effect
        uniform float darknessFactor;

        // Get screen aspect ratio
        uniform float aspectRatio;

        #ifndef FORCE_DISABLE_WEATHER
            // Get rain strength
            uniform float rainStrength;
        #endif
        
        #include "/lib/post/lensFlare.glsl"
    #endif

    #include "/lib/utility/noiseFunctions.glsl"

    #include "/lib/post/tonemap.glsl"

    void main(){
        // Screen texel coordinates
        ivec2 screenTexelCoord = ivec2(gl_FragCoord.xy);
        // Original scene color
        vec3 color = texelFetch(gcolor, screenTexelCoord, 0).rgb;

        #ifdef BLOOM
            // Get pixel size
            vec2 pixSize = 1.0 / vec2(viewWidth, viewHeight);

            // Uncompress the HDR colors and upscale
            vec3 eBloom = getBloomTile(pixSize, vec2(0), 2.0);
            eBloom += getBloomTile(pixSize, vec2(0, 0.275), 3.0);
            eBloom += getBloomTile(pixSize, vec2(0.135, 0.275), 4.0);
            eBloom += getBloomTile(pixSize, vec2(0.2075, 0.275), 5.0);
            eBloom += getBloomTile(pixSize, vec2(0.135, 0.3625), 6.0);
            eBloom += getBloomTile(pixSize, vec2(0.160625, 0.3625), 7.0);

            // Average the total samples (1 / 6 bloom tiles multiplied by 1 / 4 samples used for the box blur)
            eBloom *= 0.04166667;
            // Apply bloom by BLOOM_AMOUNT
            color = mix(color, eBloom, BLOOM_AMOUNT);
        #endif

        #if defined LENS_FLARE && defined WORLD_LIGHT
            if(textureLod(depthtex0, shdLightDirScreenSpace.xy, 0).x == 1)
                #ifdef FORCE_DISABLE_WEATHER
                    color += getLensFlare(texCoord - 0.5, shdLightDirScreenSpace.xy - 0.5) * (1.0 - blindness) * (1.0 - darknessFactor);
                #else
                    color += getLensFlare(texCoord - 0.5, shdLightDirScreenSpace.xy - 0.5) * (1.0 - blindness) * (1.0 - darknessFactor) * (1.0 - rainStrength);
                #endif
        #endif

        #ifdef AUTO_EXPOSURE
            // Get center pixel current average scene luminance and mix previous and current pixel...
            float centerPixLuminance = sumOf(textureLod(gcolor, vec2(0.5), 9).rgb);

            // Accumulate current luminance
            float tempPixLuminance = mix(centerPixLuminance, texelFetch(colortex5, ivec2(1), 0).a, exp2(-AUTO_EXPOSURE_SPEED * frameTime));

            // Apply auto exposure by dividing it by the pixel's luminance in sRGB
            color /= max(sqrt(tempPixLuminance), MIN_EXPOSURE);

            #if defined PREVIOUS_FRAME || ANTI_ALIASING >= 2
                #define TAA_DATA texelFetch(colortex5, screenTexelCoord, 0).rgb
            #else
                // vec4(0, 0, 0, tempPixLuminance)
                #define TAA_DATA 0, 0, 0
            #endif
        #endif

        // Exposure, tint, and tonemap
        color = whitePreservingLumaBasedReinhardToneMapping(color * vec3(TINT_R, TINT_G, TINT_B) * (0.00392156863 * EXPOSURE));

        #ifdef VIGNETTE
            // BSL's vignette, modified to control intensity
            color *= 1.0 - lengthSquared(texCoord - 0.5) * VIGNETTE_AMOUNT * (3.0 - sumOf(color));
        #endif

        // Gamma correction, color saturation, contrast, etc. and film grain
        color = toneA(toSRGB(color)) + (texelFetch(noisetex, screenTexelCoord & 255, 0).x - 0.5) * 0.00392156863;

    /* DRAWBUFFERS:0 */
        // Clamp final color
        gl_FragData[0] = vec4(saturate(color), 1); // gcolor

        #ifdef BLOOM
        /* DRAWBUFFERS:04 */
            gl_FragData[1] = vec4(eBloom, 1); // colortex4

            #ifdef AUTO_EXPOSURE
            /* DRAWBUFFERS:045 */
                gl_FragData[2] = vec4(TAA_DATA, tempPixLuminance); // colortex5
            #endif
        #else
            #ifdef AUTO_EXPOSURE
            /* DRAWBUFFERS:05 */
                gl_FragData[1] = vec4(TAA_DATA, tempPixLuminance); // colortex5
            #endif
        #endif
    }
#endif