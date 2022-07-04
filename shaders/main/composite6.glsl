/// ------------------------------------- /// Vertex Shader /// ------------------------------------- ///

#ifdef VERTEX
    out vec2 screenCoord;

    void main(){
        gl_Position = ftransform();
        screenCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    }
#endif

/// ------------------------------------- /// Fragment Shader /// ------------------------------------- ///

#ifdef FRAGMENT
    in vec2 screenCoord;

    uniform sampler2D gcolor;

    #ifdef AUTO_EXPOSURE
        // Needs to be true whenever auto exposure or TAA is on
        const bool colortex5MipmapEnabled = true;
        // Get previous frame color
        uniform sampler2D colortex5;

        // Get frame time
        uniform float frameTime;
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

        // Get is eye in water
        uniform int isEyeInWater;

        #include "/lib/utility/convertScreenSpace.glsl"
        
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
            color = mix(color, eBloom * 0.04166667, 0.16 * BLOOM_BRIGHTNESS);
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

            // Accumulate current luminance
            float tempPixLuminance = mix(centerPixCol.r + centerPixCol.g + centerPixCol.b, texelFetch(colortex5, ivec2(0), 0).a, exp2(-AUTO_EXPOSURE_SPEED * frameTime));

            // Apply auto exposure by dividing it by the pixel's luminance in sRGB
            color /= max(pow(tempPixLuminance, RCPGAMMA), MIN_EXPOSURE);

            #if defined PREVIOUS_FRAME || ANTI_ALIASING >= 2
                #define TAA_DATA texelFetch(colortex5, screenTexelCoord, 0).rgb
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
        color = toneA(pow(color, vec3(RCPGAMMA))) + (texelFetch(noisetex, screenTexelCoord & 255, 0).x - 0.5) * 0.00392156863;

    /* DRAWBUFFERS:0 */
        gl_FragData[0] = vec4(color, 1); // gcolor

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