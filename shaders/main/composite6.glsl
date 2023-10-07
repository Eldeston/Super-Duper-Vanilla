/*
================================ /// Super Duper Vanilla v1.3.5 /// ================================

    Developed by Eldeston, presented by FlameRender (C) Studios.

    Copyright (C) 2023 Eldeston | FlameRender (C) Studios License


    By downloading this content you have agreed to the license and its terms of use.

================================ /// Super Duper Vanilla v1.3.5 /// ================================
*/

/// Buffer features: Lens flare, applied bloom, auto exposure, tonemapping, vignette and postColOut grading

/// -------------------------------- /// Vertex Shader /// -------------------------------- ///

#ifdef VERTEX
    #if defined LENS_FLARE && defined WORLD_LIGHT
        flat out vec3 sRGBLightCol;
        flat out vec3 shdLightDirScreenSpace;
    #endif

    noperspective out vec2 texCoord;

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
            // Get sRGB light postColOut
            sRGBLightCol = LIGHT_COLOR_DATA_BLOCK0;

            // Get shadow light view direction in screen space
            shdLightDirScreenSpace = vec3(toScreenCoord(mat3(gbufferModelView) * vec3(shadowModelView[0].z, shadowModelView[1].z, shadowModelView[2].z)), gbufferProjection[1].y * 0.72794047);
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

    #if defined LENS_FLARE && defined WORLD_LIGHT
        flat in vec3 sRGBLightCol;
        flat in vec3 shdLightDirScreenSpace;
    #endif

    noperspective in vec2 texCoord;

    uniform sampler2D gcolor;

    #ifdef AUTO_EXPOSURE
        uniform float frameTime;

        uniform sampler2D colortex5;
    #endif

    #ifdef BLOOM
        uniform float pixelWidth;
        uniform float pixelHeight;

        uniform sampler2D colortex4;

        /*
        Might use this later
        
        // from http://www.java-gaming.org/index.php?topic=35123.0
        // Optimized to remove unecessary operations
        vec4 optimizedCubic(float v){
            vec3 n = vec3(1, 2, 3) - v; // 3
            vec3 s = n * n * n; // 6
            vec3 t = s * 0.16666667; // 3

            float y = t.y - 4.0 * t.x; // 2
            float z = t.z - 4.0 * t.y + s.x; // 3
            float w = 1.0 - t.x - y - z; // 3

            return vec4(t.x, y, z, w);
        }

        vec3 getBloomTile(in vec2 coords, in int LOD){
            vec2 baseCoord = (texCoord * exp2(-LOD) + coords) / vec2(pixelWidth, pixelHeight) - 0.5;
            vec2 fBaseCoord = fract(baseCoord);
            baseCoord -= fBaseCoord;

            vec4 xCubic = optimizedCubic(fBaseCoord.x);
            vec4 yCubic = optimizedCubic(fBaseCoord.y);

            vec4 c = baseCoord.xxyy + vec2(-0.5, 1.5).xyxy;

            vec4 s = vec4(xCubic.xz + xCubic.yw, yCubic.xz + yCubic.yw);
            vec4 offSet = c + vec4(xCubic.yw, yCubic.yw) / s;

            offSet *= vec4(pixelWidth, pixelWidth, pixelHeight, pixelHeight);

            vec3 sample0 = textureLod(colortex4, offSet.xz, 0).rgb;
            vec3 sample1 = textureLod(colortex4, offSet.yz, 0).rgb;
            vec3 sample2 = textureLod(colortex4, offSet.xw, 0).rgb;
            vec3 sample3 = textureLod(colortex4, offSet.yw, 0).rgb;

            float sx = s.x / (s.x + s.y);
            float sy = s.z / (s.z + s.w);

            return mix(mix(sample3, sample2, sx), mix(sample1, sample0, sx), sy);
        }
        */

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

        // Get scene color
        postColOut = texelFetch(gcolor, screenTexelCoord, 0).rgb;

        #ifdef BLOOM
            // Uncompress the HDR colors and upscale
            vec3 bloomCol = getBloomTile(vec2(0), 2);
            bloomCol += getBloomTile(vec2(0, 0.2578125), 3);
            bloomCol += getBloomTile(vec2(0.12890625, 0.2578125), 4);
            bloomCol += getBloomTile(vec2(0.1953125, 0.2578125), 5);
            bloomCol += getBloomTile(vec2(0.12890625, 0.328125), 6);

            // Average the total samples (1 / 5 bloom tiles multiplied by 1 / 4 samples used for the box blur)
            bloomCol *= 0.05;

            float bloomLuma = sumOf(bloomCol);
            // Apply bloom by tonemapped luma and BLOOM_STRENGTH
            postColOut += (bloomCol - postColOut) * ((BLOOM_STRENGTH * bloomLuma) / (3.0 + bloomLuma));
        #endif

        #if defined LENS_FLARE && defined WORLD_LIGHT
            if(textureLod(depthtex0, shdLightDirScreenSpace.xy, 0).x == 1)
                #ifdef FORCE_DISABLE_WEATHER
                    postColOut += getLensFlare(texCoord - 0.5, shdLightDirScreenSpace.xy - 0.5) * (1.0 - blindness) * (1.0 - darknessFactor);
                #else
                    postColOut += getLensFlare(texCoord - 0.5, shdLightDirScreenSpace.xy - 0.5) * (1.0 - blindness) * (1.0 - darknessFactor) * (1.0 - rainStrength);
                #endif
        #endif

        #ifdef AUTO_EXPOSURE
            // Get center pixel current average scene luminance and mix previous and current pixel...
            float centerPixLuminance = sumOf(textureLod(gcolor, vec2(0.5), 8).rgb);

            // Accumulate current luminance
            float tempPixLuminance = mix(centerPixLuminance, texelFetch(colortex5, ivec2(1), 0).a, exp2(-AUTO_EXPOSURE_SPEED * frameTime));

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
        postColOut = modifiedReinhardExtended(postColOut * exposureTint);

        // Gamma correction
        postColOut = toSRGB(postColOut);

        // Contrast and saturation
        postColOut = contrast(postColOut, CONTRAST);
        postColOut = saturation(postColOut, SATURATION);

        // Apply dithering to break postColOut banding
        postColOut += (texelFetch(noisetex, screenTexelCoord & 255, 0).x - 0.5) * 0.00392156863;
    }
#endif