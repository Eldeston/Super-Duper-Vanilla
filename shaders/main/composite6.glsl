varying vec2 texCoord;

#ifdef VERTEX
    void main(){
        gl_Position = ftransform();
        texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    }
#endif

#ifdef FRAGMENT
    uniform sampler2D gcolor;

    // Get frame time
    uniform float frameTime;

    #if ANTI_ALIASING == 2 || defined AUTO_EXPOSURE
        // Needs to be true whenever auto exposure or TAA is on
        const bool colortex6MipmapEnabled = true;
        // Needs to be false whenever auto exposure or TAA is on
        const bool colortex6Clear = false;

        #ifdef AUTO_EXPOSURE
            uniform sampler2D colortex6;
        #endif
    #endif

    #ifdef BLOOM
        uniform sampler2D colortex4;

        uniform float viewWidth;
        uniform float viewHeight;

        #include "/lib/utility/texFunctions.glsl"

        vec3 getBloomTile(vec2 uv, vec2 coords, float LOD){
            // Uncompress bloom
            return texture2DBox(colortex4, uv / exp2(LOD) + coords, vec2(viewWidth, viewHeight)).rgb;
        }
    #endif

    #ifdef LENS_FLARE
    #endif
    
    #ifdef ZA_WARUDO
    #endif
    
    #if (TIMELAPSE_MODE != 0 && defined ZA_WARUDO) || (defined LENS_FLARE && defined WORLD_LIGHT)
        uniform float aspectRatio;
    #endif

    #if defined LENS_FLARE && defined WORLD_LIGHT
        uniform sampler2D depthtex0;

        uniform mat4 gbufferProjection;
        uniform mat4 gbufferModelView;

        // Shadow view matrix uniforms
        uniform mat4 shadowModelView;

        uniform float blindness;

        #include "/lib/universalVars.glsl"

        #include "/lib/utility/convertScreenSpace.glsl"
        
        #include "/lib/post/lensFlare.glsl"
    #endif

    #include "/lib/utility/noiseFunctions.glsl"

    #include "/lib/post/tonemap.glsl"

    #if TIMELAPSE_MODE != 0 && defined ZA_WARUDO
        uniform float zaWarudo;
    #endif

    void main(){
        #if TIMELAPSE_MODE != 0 && defined ZA_WARUDO
            float zaWarudoSphere = abs(length((texCoord - 0.5) * vec2(aspectRatio, 1)) * 0.5 + 1.0 - zaWarudo);

            vec2 distortCoord = (texCoord - 0.5) - (texCoord - 0.5) * min(1.0, zaWarudoSphere) * float(zaWarudoSphere < 0.5 && zaWarudoSphere > 0) + 0.5;

            #define texCoord distortCoord
        #endif

        // Original scene color
        vec3 color = texture2D(gcolor, texCoord).rgb;

        #ifdef BLOOM
            // Uncompress the HDR colors and upscale
            vec3 eBloom = getBloomTile(texCoord, vec2(0), 2.0);
            eBloom += getBloomTile(texCoord, vec2(0, 0.275), 3.0);
            eBloom += getBloomTile(texCoord, vec2(0.135, 0.275), 4.0);
            eBloom += getBloomTile(texCoord, vec2(0.2075, 0.275), 5.0);
            eBloom += getBloomTile(texCoord, vec2(0.135, 0.3625), 6.0);
            eBloom += getBloomTile(texCoord, vec2(0.160625, 0.3625), 7.0);
            eBloom = eBloom * 0.16666667;

            color = mix(color, eBloom, 0.2 * BLOOM_BRIGHTNESS);
        #endif

        #if defined LENS_FLARE && defined WORLD_LIGHT
            vec2 lightDir = toScreen(mat3(gbufferModelView) * vec3(shadowModelView[0].z, shadowModelView[1].z, shadowModelView[2].z)).xy;
            // also equivalent to:
            // vec3(0, 0, 1) * mat3(shadowModelView) = vec3(shadowModelView[0].z, shadowModelView[1].z, shadowModelView[2].z)
            // shadowLightPosition is broken in other dimensions. The current is equivalent to:
            // normalize(mat3(gbufferModelViewInverse) * shadowLightPosition + gbufferModelViewInverse[3].xyz)
            
            if(texture2D(depthtex0, lightDir).x == 1 && isEyeInWater == 0)
                color += getLensFlare(texCoord - 0.5, lightDir - 0.5) * (1.0 - blindness) * (1.0 - rainStrength);
        #endif

        #ifdef AUTO_EXPOSURE
            // Get center pixel current average scene luminance and mix previous and current pixel...
            float tempPixelLuminance = mix(sqrt(length(texture2D(gcolor, vec2(0.5), 10.0).rgb)), texture2D(colortex6, vec2(0)).a, exp2(-AUTO_EXPOSURE_SPEED * frameTime));

            // Apply auto exposure
            color /= max(tempPixelLuminance, 0.05);

            #if ANTI_ALIASING == 2
                #define TAA_DATA texture2D(colortex6, texCoord).rgb
            #else
                // vec4(0, 0, 0, tempPixelLuminance)
                #define TAA_DATA 0, 0, 0
            #endif
        #endif

        // Exposeure, tint, and tonemap
        color = whitePreservingLumaBasedReinhardToneMapping(color * vec3(TINT_R, TINT_G, TINT_B) * (0.00392156863 * EXPOSURE));

        #ifdef VIGNETTE
            // BSL's vignette, modified to control intensity
            color *= max(0.0, 1.0 - length(texCoord - 0.5) * VIGNETTE_INTENSITY * (1.0 - getLuminance(color)));
        #endif

        // Gamma correction
        const vec3 gammaRcp = vec3(1.0 / GAMMA);
        color = pow(color, gammaRcp);
        
        // Color saturation, contrast, etc. and film grain
        color = toneA(color) + (texture2D(noisetex, gl_FragCoord.xy * 0.03125).x - 0.5) * 0.00392156863;

        #if TIMELAPSE_MODE != 0 && defined ZA_WARUDO
            color = mix(color, 1.0 - saturate(color), smoothstep(0.51, 0.49, zaWarudoSphere));
        #endif

    /* DRAWBUFFERS:0 */
        gl_FragData[0] = vec4(color, 1); //gcolor

        #ifdef BLOOM
        /* DRAWBUFFERS:04 */
            gl_FragData[1] = vec4(eBloom, 1); //colortex4

            #ifdef AUTO_EXPOSURE
            /* DRAWBUFFERS:046 */
                gl_FragData[2] = vec4(TAA_DATA, tempPixelLuminance); //colortex6
            #endif
        #else
            #ifdef AUTO_EXPOSURE
            /* DRAWBUFFERS:06 */
                gl_FragData[1] = vec4(TAA_DATA, tempPixelLuminance); //colortex6
            #endif
        #endif
    }
#endif