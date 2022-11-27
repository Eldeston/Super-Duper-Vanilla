/// ------------------------------------- /// Vertex Shader /// ------------------------------------- ///

#ifdef VERTEX
    #if defined LENS_FLARE && defined WORLD_LIGHT
        flat out vec3 sRGBLightCol;
        flat out vec3 shdLightViewDir;
    #endif

    out vec2 screenCoord;

    #if defined LENS_FLARE && defined WORLD_LIGHT
        // Model view matrix
        uniform mat4 gbufferModelView;

        // Shadow model view matrix
        uniform mat4 shadowModelView;

        #include "/lib/universalVars.glsl"
    #endif

    void main(){
        screenCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

        #if defined LENS_FLARE && defined WORLD_LIGHT
            // Get sRGB light color
            sRGBLightCol = LIGHT_COL_DATA_BLOCK;

            // Get shadow light view direction
            shdLightViewDir = mat3(gbufferModelView) * vec3(shadowModelView[0].z, shadowModelView[1].z, shadowModelView[2].z);
        #endif

        gl_Position = ftransform();
    }
#endif

/// ------------------------------------- /// Fragment Shader /// ------------------------------------- ///

#ifdef FRAGMENT
    #if defined LENS_FLARE && defined WORLD_LIGHT
        flat in vec3 sRGBLightCol;
        flat in vec3 shdLightViewDir;
    #endif

    in vec2 screenCoord;

    uniform sampler2D gcolor;

    #ifdef AUTO_EXPOSURE
        // Get previous frame color
        uniform sampler2D colortex5;

        // Get frame time
        uniform float frameTime;
    #endif

    #ifdef BLOOM
        uniform sampler2D colortex4;

        uniform float viewWidth;
        uniform float viewHeight;

        vec3 getBloomTile(in vec2 pixSize, in vec2 coords, in float LOD){
            // Remap to bloom tile texture coordinates
            vec2 texCoord = screenCoord / exp2(LOD) + coords;

            vec2 topRightCorner = texCoord + pixSize;
            vec2 bottomLeftCorner = texCoord - pixSize;

            // Apply box blur all tiles
            return textureLod(colortex4, bottomLeftCorner, 0).rgb + textureLod(colortex4, topRightCorner, 0).rgb +
                textureLod(colortex4, vec2(bottomLeftCorner.x, topRightCorner.y), 0).rgb + textureLod(colortex4, vec2(topRightCorner.x, bottomLeftCorner.y), 0).rgb;
        }
    #endif

    #ifdef LENS_FLARE
    #endif

    #if defined LENS_FLARE && defined WORLD_LIGHT
        uniform sampler2D depthtex0;

        // Projection matrix uniforms
        uniform mat4 gbufferProjection;

        // Get blindess
        uniform float blindness;
        // Get darkness effect
        uniform float darknessFactor;

        // Get screen aspect ratio
        uniform float aspectRatio;

        // Get rain strength
        #ifdef FORCE_DISABLE_WEATHER
            const float rainStrength = 0.0;
        #else
            uniform float rainStrength;
        #endif

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
            color = mix(color, eBloom * 0.04166667, BLOOM_AMOUNT);
        #endif

        #if defined LENS_FLARE && defined WORLD_LIGHT
            vec2 lightDir = toScreen(shdLightViewDir).xy;
            // also equivalent to:
            // vec3(0, 0, 1) * mat3(shadowModelView) = vec3(shadowModelView[0].z, shadowModelView[1].z, shadowModelView[2].z)
            // shadowLightPosition is broken in other dimensions. The current is equivalent to:
            // fastNormalize(mat3(gbufferModelViewInverse) * shadowLightPosition + gbufferModelViewInverse[3].xyz)
            
            if(textureLod(depthtex0, lightDir, 0).x == 1)
                color += getLensFlare(screenCoord - 0.5, lightDir - 0.5) * (1.0 - blindness) * (1.0 - darknessFactor) * (1.0 - rainStrength);
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
            color *= 1.0 - lengthSquared(screenCoord - 0.5) * VIGNETTE_AMOUNT * (3.0 - sumOf(color));
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