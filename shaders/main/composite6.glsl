varying vec2 screenCoord;

#ifdef VERTEX
    void main(){
        gl_Position = ftransform();
        screenCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    }
#endif

#ifdef FRAGMENT
    uniform sampler2D gcolor;

    #if ANTI_ALIASING == 2 || defined AUTO_EXPOSURE
        // Needs to be false whenever auto exposure or TAA is on
        const bool colortex6Clear = false;

        #ifdef AUTO_EXPOSURE
            // Needs to be true whenever auto exposure or TAA is on
            const bool colortex6MipmapEnabled = true;
            // Get previous frame color
            uniform sampler2D colortex6;

            // Get frame time
            uniform float frameTime;
        #endif
    #endif

    #ifdef BLOOM
        uniform sampler2D colortex4;

        uniform float viewWidth;
        uniform float viewHeight;

        vec3 getBloomTile(vec2 pixSize, vec2 coords, float LOD){
            // Remap to bloom tile texture coordinates
            vec2 texCoord = screenCoord / exp2(LOD) + coords;

            // Apply box blur all tiles
            // return (texture2D(colortex4, texCoord - pixSize).rgb + texture2D(colortex4, texCoord + pixSize).rgb +
            //    texture2D(colortex4, texCoord - vec2(pixSize.x, -pixSize.y)).rgb + texture2D(colortex4, texCoord + vec2(pixSize.x, -pixSize.y)).rgb) * 0.25;
            return texture2D(colortex4, texCoord - pixSize).rgb + texture2D(colortex4, texCoord + pixSize).rgb +
                texture2D(colortex4, texCoord - vec2(pixSize.x, -pixSize.y)).rgb + texture2D(colortex4, texCoord + vec2(pixSize.x, -pixSize.y)).rgb;
        }
    #endif

    #ifdef LENS_FLARE
    #endif

    #if defined LENS_FLARE && defined WORLD_LIGHT
        uniform sampler2D depthtex0;

        uniform mat4 gbufferProjection;
        uniform mat4 gbufferModelView;

        // Shadow view matrix uniforms
        uniform mat4 shadowModelView;

        uniform float blindness;
        uniform float aspectRatio;

        #include "/lib/universalVars.glsl"

        // Get eye in water uniform
        uniform int isEyeInWater;

        #include "/lib/utility/convertScreenSpace.glsl"
        
        #include "/lib/post/lensFlare.glsl"
    #endif

    #include "/lib/utility/noiseFunctions.glsl"

    #include "/lib/post/tonemap.glsl"

    void main(){
        // Original scene color
        vec3 color = texture2D(gcolor, screenCoord).rgb;

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

            // Average the total samples
            // eBloom *= 0.16666667 * 0.25;
            eBloom *= 0.04166666;

            // Apply bloom
            color = mix(color, eBloom, 0.18 * BLOOM_BRIGHTNESS);
        #endif

        #if defined LENS_FLARE && defined WORLD_LIGHT
            vec2 lightDir = toScreen(mat3(gbufferModelView) * vec3(shadowModelView[0].z, shadowModelView[1].z, shadowModelView[2].z)).xy;
            // also equivalent to:
            // vec3(0, 0, 1) * mat3(shadowModelView) = vec3(shadowModelView[0].z, shadowModelView[1].z, shadowModelView[2].z)
            // shadowLightPosition is broken in other dimensions. The current is equivalent to:
            // normalize(mat3(gbufferModelViewInverse) * shadowLightPosition + gbufferModelViewInverse[3].xyz)
            
            if(texture2D(depthtex0, lightDir).x == 1 && isEyeInWater == 0)
                color += getLensFlare(screenCoord - 0.5, lightDir - 0.5) * (1.0 - blindness) * (1.0 - rainStrength);
        #endif

        #ifdef AUTO_EXPOSURE
            // Get center pixel current average scene luminance and mix previous and current pixel...
            vec3 centerPixCol = texture2D(gcolor, vec2(0.5), 10.0).rgb;

            float tempPixLuminance = mix(centerPixCol.r + centerPixCol.g + centerPixCol.b, texture2D(colortex6, vec2(0)).a, exp2(-AUTO_EXPOSURE_SPEED * frameTime));

            // Apply auto exposure by dividing it by the pixel's luminance in sRGB
            color /= max(pow(tempPixLuminance, RCPGAMMA), MIN_EXPOSURE);

            #if ANTI_ALIASING == 2
                #define TAA_DATA texture2D(colortex6, screenCoord).rgb
            #else
                // vec4(0, 0, 0, tempPixLuminance)
                #define TAA_DATA 0, 0, 0
            #endif
        #endif

        // Exposeure, tint, and tonemap
        color = whitePreservingLumaBasedReinhardToneMapping(color * vec3(TINT_R, TINT_G, TINT_B) * (0.00392156863 * EXPOSURE));

        #ifdef VIGNETTE
            // BSL's vignette, modified to control intensity
            color *= max(0.0, 1.0 - length(screenCoord - 0.5) * VIGNETTE_INTENSITY * (1.0 - getLuminance(color)));
        #endif

        // Gamma correction, color saturation, contrast, etc. and film grain
        color = toneA(pow(color, vec3(RCPGAMMA))) + (texture2D(noisetex, gl_FragCoord.xy * 0.03125).x - 0.5) * 0.00392156863;

    /* DRAWBUFFERS:0 */
        gl_FragData[0] = vec4(color, 1); // gcolor

        #ifdef BLOOM
        /* DRAWBUFFERS:04 */
            gl_FragData[1] = vec4(eBloom, 1); //colortex4

            #ifdef AUTO_EXPOSURE
            /* DRAWBUFFERS:046 */
                gl_FragData[2] = vec4(TAA_DATA, tempPixLuminance); //colortex6
            #endif
        #else
            #ifdef AUTO_EXPOSURE
            /* DRAWBUFFERS:06 */
                gl_FragData[1] = vec4(TAA_DATA, tempPixLuminance); //colortex6
            #endif
        #endif
    }
#endif