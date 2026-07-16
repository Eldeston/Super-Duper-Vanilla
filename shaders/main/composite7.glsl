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

        #include "/lib/utility/projectionFunctions.glsl"
    #endif

    void main(){
        texCoord = gl_MultiTexCoord0.xy;

        #if defined LENS_FLARE && defined WORLD_LIGHT
            // Get sRGB light postColOut
            sRGBLightCol = LIGHT_COLOR_DATA_BLOCK0;

            // Get shadow light view direction in screen space
            shdLightDirScreenSpace = vec3(getScreenCoord(gbufferProjection, mat3(gbufferModelView) * vec3(shadowModelView[0].z, shadowModelView[1].z, shadowModelView[2].z)), gbufferProjection[1].y * 0.72794047);
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

    uniform sampler2D colortex4;

    #ifdef AUTO_EXPOSURE
        uniform float frameTime;

        uniform sampler2D colortex5;
    #endif

    #ifdef BLOOM
        uniform float viewWidth;
        uniform float viewHeight;

        uniform float pixelWidth;
        uniform float pixelHeight;

        uniform sampler2D colortex0;

        // from http://www.java-gaming.org/index.php?topic=35123.0
        vec4 cubic(float v){
            const float cubicConst = 1.0 / 6.0;

            vec4 n = vec4(1, 2, 3, 4) - v;
            vec4 s = n * n * n;
            float x = s.x;
            float y = s.y - 4.0 * s.x;
            float z = s.z - 4.0 * s.y + 6.0 * s.x;
            float w = 6.0 - x - y - z;
            return vec4(x, y, z, w) * cubicConst;
        }

        vec3 getBloomTile(in vec2 coords, in float invScale){
            vec2 texSize = vec2(viewWidth, viewHeight);
            vec2 invTexSize = vec2(pixelWidth, pixelHeight);
            
            vec2 texCoords = (texCoord * invScale + coords) * texSize - 0.5;
        
            vec2 fxy = fract(texCoords);
            texCoords -= fxy;

            vec4 xcubic = cubic(fxy.x);
            vec4 ycubic = cubic(fxy.y);

            vec4 c = texCoords.xxyy + vec2(-0.5, 1.5).xyxy;
            
            vec4 s = vec4(xcubic.xz + xcubic.yw, ycubic.xz + ycubic.yw);
            vec4 offset = c + vec4(xcubic.yw, ycubic.yw) / s;
            
            offset *= invTexSize.xxyy;
            
            vec3 sample0 = textureLod(colortex0, offset.xz, 0).rgb;
            vec3 sample1 = textureLod(colortex0, offset.yz, 0).rgb;
            vec3 sample2 = textureLod(colortex0, offset.xw, 0).rgb;
            vec3 sample3 = textureLod(colortex0, offset.yw, 0).rgb;

            float sx = s.x / (s.x + s.y);
            float sy = s.z / (s.z + s.w);

            return mix(mix(sample3, sample2, sx), mix(sample1, sample0, sx), sy);
        }
    #endif

    #if defined LENS_FLARE && defined WORLD_LIGHT
        uniform float blindness;
        uniform float darknessFactor;

        uniform float aspectRatio;

        uniform sampler2D depthtex0;

        #ifdef DISTANT_HORIZONS
            uniform sampler2D dhDepthTex1;
        #endif

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
        postColOut = texelFetch(colortex4, screenTexelCoord, 0).rgb;

        #ifdef BLOOM
            // Uncompress the HDR colors and upscale
            vec3 bloomCol = getBloomTile(vec2(0), 0.25);
            bloomCol += getBloomTile(vec2(0, 0.2578125), 0.125);
            bloomCol += getBloomTile(vec2(0.12890625, 0.2578125), 0.0625);
            bloomCol += getBloomTile(vec2(0.1953125, 0.2578125), 0.03125);
            bloomCol += getBloomTile(vec2(0.12890625, 0.328125), 0.015625);

            // Average the total samples (1 / 5 bloom tiles multiplied by 1 / 4 samples used for the box blur)
            bloomCol *= 0.2;

            float bloomLuma = sumOf(bloomCol);
            // Apply bloom by tonemapped luma and BLOOM_STRENGTH
            postColOut += bloomCol * ((BLOOM_STRENGTH * bloomLuma) / (3.0 + bloomLuma));
        #endif

        #if defined LENS_FLARE && defined WORLD_LIGHT
            #ifdef DISTANT_HORIZONS
                bool isSky = textureLod(dhDepthTex1, shdLightDirScreenSpace.xy, 0).x == 1 && getDepth(depthtex0, shdLightDirScreenSpace.xy, 0) == 1;
            #else
                bool isSky = getDepth(depthtex0, shdLightDirScreenSpace.xy, 0) == 1;
            #endif

            #ifdef FORCE_DISABLE_WEATHER
                if(isSky) postColOut += getLensFlare(texCoord - 0.5, shdLightDirScreenSpace.xy - 0.5) * (1.0 - blindness) * (1.0 - darknessFactor);
            #else
                if(isSky) postColOut += getLensFlare(texCoord - 0.5, shdLightDirScreenSpace.xy - 0.5) * (1.0 - blindness) * (1.0 - darknessFactor) * (1.0 - rainStrength);
            #endif
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