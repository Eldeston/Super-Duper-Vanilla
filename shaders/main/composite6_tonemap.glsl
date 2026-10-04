/*
================================ /// Super Duper Vanilla v1.3.8 /// ================================

    Developed by Eldeston, presented by FlameRender (C) Studios.

    Copyright (C) 2023 Eldeston | FlameRender (C) Studios License


    By downloading this content you have agreed to the license and its terms of use.

================================ /// Super Duper Vanilla v1.3.8 /// ================================
*/

/// Buffer features: Lens flare, applied bloom, auto exposure, tonemapping, vignette and postColOut grading

/// -------------------------------- /// Vertex Shader /// -------------------------------- ///

#ifdef VERTEX
    #if defined LENS_FLARE && defined WORLD_LIGHT
        flat out vec3 sRGBLightCol;
        flat out vec3 shdLightDirScreenSpace;
        #if WORLD_ID == 0
            flat out float lightningFlareFactor;
            flat out float lightningBoltDepth;
        #endif
    #endif

    noperspective out vec2 texCoord;

    #if defined LENS_FLARE && defined WORLD_LIGHT
        uniform mat4 gbufferProjection;

        uniform mat4 gbufferModelView;

        uniform mat4 shadowModelView;

        #if WORLD_ID == 1
            uniform float endFlashIntensity;
            uniform vec3 endFlashPosition;
        #endif

        #ifndef FORCE_DISABLE_WEATHER
            uniform float rainStrength;
            uniform float weatherFade;
            #if WORLD_ID == 0
                #ifndef THUNDER_STRENGTH_DECLARED
                    #define THUNDER_STRENGTH_DECLARED
                    uniform float thunderStrength;
                #endif
            #endif
        #endif

        #ifndef FORCE_DISABLE_DAY_CYCLE
            uniform float dayCycle;
            uniform float twilightPhase;
        #endif

        #if WORLD_ID == 0
            #ifndef LIGHTNING_BOLT_POS_DECLARED
                #define LIGHTNING_BOLT_POS_DECLARED
                uniform vec4 lightningBoltPosition;
            #endif
            uniform float lightningFlash;
            uniform float fragmentFrameTime;
            #include "/lib/atmospherics/lightning.glsl"
        #endif

        #include "/lib/utility/projectionFunctions.glsl"
    #endif

    void main(){
        texCoord = gl_MultiTexCoord0.xy;

        #if defined LENS_FLARE && defined WORLD_LIGHT
            #if WORLD_ID == 1
                const vec3 blackHoleDir = vec3(0.0, 0.6691306, -0.7431448);
                #ifndef EPILEPSY_SAFETY
                    float flashFlareWeight = smoothstep(0.18, 0.50, endFlashIntensity);
                #else
                    float flashFlareWeight = 0.0;
                #endif
                if (flashFlareWeight > 0.0 && endFlashPosition.z < -0.01) {
                    sRGBLightCol = vec3(1.2, 1.0, 1.5) * (endFlashIntensity * flashFlareWeight);
                    shdLightDirScreenSpace = vec3(getScreenCoord(gbufferProjection, normalize(endFlashPosition)), gbufferProjection[1].y * 0.72794047);
                } else {
                    #ifdef END_BH_LIGHT
                        if(END_BH_LIGHT > 0.0){
                            vec3 bhViewDir = mat3(gbufferModelView) * blackHoleDir;
                            if(bhViewDir.z < -0.01){
                                sRGBLightCol = LIGHT_COLOR_DATA_BLOCK0 * (END_BH_LIGHT * 0.65);
                                shdLightDirScreenSpace = vec3(getScreenCoord(gbufferProjection, bhViewDir), gbufferProjection[1].y * 0.72794047);
                            } else {
                                sRGBLightCol = vec3(0.0);
                                shdLightDirScreenSpace = vec3(-10.0, -10.0, 0.0);
                            }
                        } else {
                            sRGBLightCol = vec3(0.0);
                            shdLightDirScreenSpace = vec3(0.0);
                        }
                    #else
                        sRGBLightCol = vec3(0.0);
                        shdLightDirScreenSpace = vec3(0.0);
                    #endif
                }
            #else
                #if WORLD_ID == 0 && !defined EPILEPSY_SAFETY
                    float lightningIntensity = 0.0;
                    vec3 lightningViewPos = vec3(0.0);
                    float boltClipDepth = 1.0;

                    if (lightningBoltPosition.w > 0.001 && lengthSquared(lightningBoltPosition.xyz) > 0.001) {
                        lightningIntensity = max(lightningFlash, 0.40);
                        lightningViewPos = mat3(gbufferModelView) * lightningBoltPosition.xyz;
                        vec4 boltClip = gbufferProjection * vec4(lightningViewPos, 1.0);
                        boltClipDepth = (boltClip.z / boltClip.w) * 0.5 + 0.5;
                    } else {
                        LightningStrikeState ccState = getCloudLightningState();
                        if (ccState.isActive && ccState.flash > 0.01) {
                            lightningIntensity = ccState.flash;
                            lightningViewPos = mat3(gbufferModelView) * ccState.dir;
                            boltClipDepth = 1.0;
                        }
                    }

                    float flashFlareWeight = smoothstep(0.04, 0.35, lightningIntensity);
                #else
                    float flashFlareWeight = 0.0;
                #endif

                if (flashFlareWeight > 0.0 && lightningViewPos.z < -0.01) {
                    sRGBLightCol = LIGHTNING_COLOR * (lightningIntensity * flashFlareWeight * 2.5);
                    shdLightDirScreenSpace = vec3(getScreenCoord(gbufferProjection, normalize(lightningViewPos)), gbufferProjection[1].y * 0.72794047);
                    #if WORLD_ID == 0
                        lightningFlareFactor = flashFlareWeight;
                        lightningBoltDepth = boltClipDepth;
                    #endif
                } else {
                    #if WORLD_ID == 0
                        lightningFlareFactor = 0.0;
                        lightningBoltDepth = 1.0;
                    #endif
                    // Get sRGB light postColOut
                    sRGBLightCol = LIGHT_COLOR_DATA_BLOCK0;

                    // Get shadow light view direction in screen space
                    vec3 lightViewDir = mat3(gbufferModelView) * vec3(shadowModelView[0].z, shadowModelView[1].z, shadowModelView[2].z);
                    if(lightViewDir.z < -0.001){
                        shdLightDirScreenSpace = vec3(getScreenCoord(gbufferProjection, lightViewDir), gbufferProjection[1].y * 0.72794047);
                    } else {
                        shdLightDirScreenSpace = vec3(-10.0, -10.0, 0.0);
                    }
                }
            #endif
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
        #if WORLD_ID == 0
            flat in float lightningFlareFactor;
            flat in float lightningBoltDepth;
        #endif
    #endif

    noperspective in vec2 texCoord;

    uniform sampler2D colortex4;

    #ifdef AUTO_EXPOSURE
        uniform float frameTime;

        uniform sampler2D colortex5;
    #endif

    #ifdef BLOOM
        uniform float pixelWidth;
        uniform float pixelHeight;

        uniform sampler2D colortex0;

        vec3 getBloomTile(in vec2 coords, in float invScale){
            // Remap to bloom tile texture coordinates
            vec2 baseCoord = texCoord * invScale + coords;

            // Pixel size
            vec2 pixelSize = vec2(pixelWidth, pixelHeight);

            vec2 topRightCorner = baseCoord + pixelSize;
            vec2 bottomLeftCorner = baseCoord - pixelSize;

            // Apply box blur all tiles
            return textureLod(colortex0, bottomLeftCorner, 0).rgb + textureLod(colortex0, topRightCorner, 0).rgb +
                textureLod(colortex0, vec2(bottomLeftCorner.x, topRightCorner.y), 0).rgb + textureLod(colortex0, vec2(topRightCorner.x, bottomLeftCorner.y), 0).rgb;
        }
    #endif

    #if defined LENS_FLARE && defined WORLD_LIGHT
        uniform float blindness;
        uniform float darknessFactor;

        uniform float aspectRatio;

        uniform sampler2D depthtex0;

        #ifdef DISTANT_HORIZONS
            uniform sampler2D dhDepthTex1;
        #elif defined VOXY
            uniform sampler2D vxDepthTexOpaque;
        #endif

        #ifndef FORCE_DISABLE_WEATHER
            uniform float rainStrength;
            uniform float weatherFade;
            #if WORLD_ID == 0
                #ifndef THUNDER_STRENGTH_DECLARED
                    #define THUNDER_STRENGTH_DECLARED
                    uniform float thunderStrength;
                #endif
            #endif
        #endif

        #ifndef FORCE_DISABLE_DAY_CYCLE
            uniform float dayCycle;
        #endif

        #include "/lib/post/lensFlare.glsl"
    #endif

    #include "/lib/utility/noiseFunctions.glsl"

    #include "/lib/post/tonemap.glsl"

    #if defined LENS_FLARE && defined WORLD_LIGHT && !defined FORCE_DISABLE_CLOUDS && CLOUD_TYPE != 0
        float getCloudFlareOcclusion(in vec2 lightScreenPos){
            bool onScreen = clamp(lightScreenPos, 0.0, 1.0) == lightScreenPos;
            if(!onScreen) return 1.0;

            vec2 sunOffset = vec2(0.012 / aspectRatio, 0.012);
            vec3 s0 = textureLod(colortex4, lightScreenPos, 0.0).rgb;
            vec3 s1 = textureLod(colortex4, lightScreenPos + vec2(sunOffset.x, 0.0), 0.0).rgb;
            vec3 s2 = textureLod(colortex4, lightScreenPos - vec2(sunOffset.x, 0.0), 0.0).rgb;
            vec3 s3 = textureLod(colortex4, lightScreenPos + vec2(0.0, sunOffset.y), 0.0).rgb;
            vec3 s4 = textureLod(colortex4, lightScreenPos - vec2(0.0, sunOffset.y), 0.0).rgb;
            vec3 celestialSample = (s0 * 2.0 + s1 + s2 + s3 + s4) * (1.0 / 6.0);

            float lightLuma = getLuminance(celestialSample);
            float baseLightLuma = max(getLuminance(toLinear(sRGBLightCol)), 0.005);
            float lumaRatio = lightLuma / baseLightLuma;
            return smoothstep(2.8, 5.5, lumaRatio);
        }
    #endif

    #if defined LENS_FLARE && defined WORLD_LIGHT
        vec3 computeAppliedLensFlare(in vec2 coord){
            if(shdLightDirScreenSpace.z <= 0.0) return vec3(0.0);

            #ifdef DISTANT_HORIZONS
                bool isSky = textureLod(dhDepthTex1, shdLightDirScreenSpace.xy, 0).x == 1 && textureLod(depthtex0, shdLightDirScreenSpace.xy, 0).x == 1;
            #elif defined VOXY
                float vxDepth = textureLod(vxDepthTexOpaque, shdLightDirScreenSpace.xy, 0).x;
                bool isSky = (vxDepth >= 1.0 || vxDepth <= 0.0) && textureLod(depthtex0, shdLightDirScreenSpace.xy, 0).x == 1;
            #else
                bool isSky = textureLod(depthtex0, shdLightDirScreenSpace.xy, 0).x == 1;
            #endif

            #if WORLD_ID == 0
                float sceneDepth = textureLod(depthtex0, shdLightDirScreenSpace.xy, 0).x;
                bool canFlare = (lightningFlareFactor > 0.0) ? (sceneDepth >= lightningBoltDepth - 0.003) : isSky;
            #else
                bool canFlare = isSky;
            #endif
            if(!canFlare) return vec3(0.0);

            #ifdef FORCE_DISABLE_WEATHER
                float weatherFlare = 1.0;
            #else
                #if WORLD_ID == 0
                    float weatherFlare = lightningFlareFactor > 0.0 ? lightningFlareFactor : (1.0 - clamp(max(weatherFade, thunderStrength), 0.0, 1.0));
                #else
                    float weatherFlare = 1.0 - weatherFade;
                #endif
            #endif
            if(weatherFlare <= 0.0) return vec3(0.0);

            #if defined FORCE_DISABLE_CLOUDS || CLOUD_TYPE == 0
                float cloudFlare = 1.0;
            #else
                #if WORLD_ID == 0
                    float cloudFlare = lightningFlareFactor > 0.0 ? 1.0 : getCloudFlareOcclusion(shdLightDirScreenSpace.xy);
                #else
                    float cloudFlare = getCloudFlareOcclusion(shdLightDirScreenSpace.xy);
                #endif
            #endif
            if(cloudFlare <= 0.001) return vec3(0.0);

            return getLensFlare(coord - 0.5, shdLightDirScreenSpace.xy - 0.5) * (cloudFlare * weatherFlare * (1.0 - blindness) * (1.0 - darknessFactor));
        }
    #endif

    void main(){
        // Screen texel coordinates
        ivec2 screenTexelCoord = ivec2(gl_FragCoord.xy);

        // Get scene color
        postColOut = texelFetch(colortex4, screenTexelCoord, 0).rgb;

        #ifdef BLOOM
            if(BLOOM_STRENGTH > 0.0){
                // Uncompress the HDR colors and upscale
                vec3 bloomCol = getBloomTile(vec2(0), 0.25);
                bloomCol += getBloomTile(vec2(0, 0.2578125), 0.125);
                bloomCol += getBloomTile(vec2(0.12890625, 0.2578125), 0.0625);
                bloomCol += getBloomTile(vec2(0.1953125, 0.2578125), 0.03125);
                bloomCol += getBloomTile(vec2(0.12890625, 0.328125), 0.015625);

                // Average the total samples (1 / 5 bloom tiles multiplied by 1 / 4 samples used for the box blur)
                bloomCol *= 0.05;

                float bloomLuma = sumOf(bloomCol);
                // Apply bloom by tonemapped luma and BLOOM_STRENGTH
                postColOut += (bloomCol - postColOut) * ((BLOOM_STRENGTH * bloomLuma) / (3.0 + bloomLuma));
            }
        #endif

        #if defined LENS_FLARE && defined WORLD_LIGHT
            postColOut += computeAppliedLensFlare(texCoord);
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