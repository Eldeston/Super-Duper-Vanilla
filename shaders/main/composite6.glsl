/*
================================ /// Super Duper Vanilla v1.3.4 /// ================================

    Developed by Eldeston, presented by FlameRender (TM) Studios.

    Copyright (C) 2023 Eldeston | FlameRender (TM) Studios License


    By downloading this content you have agreed to the license and its terms of use.

================================ /// Super Duper Vanilla v1.3.4 /// ================================
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
        texCoord = gl_MultiTexCoord0.xy;

        #if defined LENS_FLARE && defined WORLD_LIGHT
            // Get sRGB light color
            sRGBLightCol = LIGHT_COL_DATA_BLOCK0;

            // Get shadow light view direction in screen space
            shdLightDirScreenSpace = vec3(toScreenCoord(mat3(gbufferModelView) * vec3(shadowModelView[0].z, shadowModelView[1].z, shadowModelView[2].z)), gbufferProjection[1].y * 0.72794047);
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
        uniform float frameTime;

        uniform sampler2D colortex5;
    #endif

    #ifdef BLOOM
        uniform float pixelWidth;
        uniform float pixelHeight;

        uniform sampler2D colortex4;

        vec3 getBloomTile(in vec2 coords, in int LOD){
            // Remap to bloom tile texture coordinates
            vec2 baseCoord = texCoord * exp2(-LOD) + coords;

            // Pixel size
            vec2 pixelSize = vec2(pixelWidth, pixelHeight);

            vec2 topRightCorner = baseCoord + pixelSize;
            vec2 bottomLeftCorner = baseCoord - pixelSize;

            // Apply box blur all tiles
            return textureLod(colortex4, bottomLeftCorner, 0).rgb + textureLod(colortex4, topRightCorner, 0).rgb +
                textureLod(colortex4, vec2(bottomLeftCorner.x, topRightCorner.y), 0).rgb + textureLod(colortex4, vec2(topRightCorner.x, bottomLeftCorner.y), 0).rgb;
        }
    #endif

    #if defined LENS_FLARE && defined WORLD_LIGHT
        uniform float blindness;
        uniform float darknessFactor;

        uniform float aspectRatio;

        uniform sampler2D depthtex0;

        #ifndef FORCE_DISABLE_WEATHER
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
            // Uncompress the HDR colors and upscale
            vec3 bloomCol = getBloomTile(vec2(0), 2);
            bloomCol += getBloomTile(vec2(0, 0.2578125), 3);
            bloomCol += getBloomTile(vec2(0.12890625, 0.2578125), 4);
            bloomCol += getBloomTile(vec2(0.1953125, 0.2578125), 5);
            bloomCol += getBloomTile(vec2(0.12890625, 0.328125), 6);

            // Average the total samples (1 / 5 bloom tiles multiplied by 1 / 4 samples used for the box blur)
            bloomCol *= 0.05;
            // Apply bloom by BLOOM_STRENGTH
            color = mix(color, bloomCol, BLOOM_STRENGTH);
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

            #if (defined PREVIOUS_FRAME && (defined SSR || defined SSGI)) || ANTI_ALIASING >= 2
                #define TAA_DATA texelFetch(colortex5, screenTexelCoord, 0).rgb
            #else
                // vec4(0, 0, 0, tempPixLuminance)
                #define TAA_DATA 0, 0, 0
            #endif
        #endif

        #ifdef VIGNETTE
            color *= max(0.0, 1.0 - lengthSquared(texCoord - 0.5) * VIGNETTE_STRENGTH);
        #endif

        // Color tinting, exposure, and tonemapping
        const vec3 exposureTint = vec3(TINT_R, TINT_G, TINT_B) * (EXPOSURE * 0.00392156863);
        color = modifiedReinhardTonemapping(color * exposureTint);

        // Gamma correction
        color = toSRGB(color);

        // Contrast and saturation
        color = contrast(color, CONTRAST);
        color = saturation(color, SATURATION);

        // Apply dithering to break color banding
        color += (texelFetch(noisetex, screenTexelCoord & 255, 0).x - 0.5) * 0.00392156863;

    /* DRAWBUFFERS:3 */
        gl_FragData[0] = vec4(color, 1); // colortex3

        #ifdef AUTO_EXPOSURE
        /* DRAWBUFFERS:35 */
            gl_FragData[1] = vec4(TAA_DATA, tempPixLuminance); // colortex5
        #endif
    }
#endif