#if defined WORLD_LIGHT && defined SHADOW_MAPPING
    vec3 getShdMapping(in vec3 normal, in float NLZ, in float parallaxShd, in float ss, in bool isShadow, in bool isSubSurface){
        vec3 feetPlayerPos = vertexFeetPlayerPos;

        #ifdef ENTITIES
            // Fixes boats having water shadows inside them
            // Not the best fix for a water leak in a boat
            if(entityId == 10133) feetPlayerPos.y += 0.2;
        #endif

        // Get shadow pos
        vec3 shdPos = vec3(shadowProjection[0].x, shadowProjection[1].y, shadowProjection[2].z) * (mat3(shadowModelView) * feetPlayerPos + shadowModelView[3].xyz);
        shdPos.z += shadowProjection[3].z;

        // Apply shadow distortion and transform to shadow screen space
        float distortShape = getDistortShape(shdPos.xy);
        shdPos = getShdDistort(shdPos, distortShape);

        // Removes the extra blobs at the edges occurring from shadow distortion
        if(shdPos.x < 0 || shdPos.x > 1 || shdPos.y < 0 || shdPos.y > 1) return vec3(1);

        // Items that are not subject to depth do not need a bias
        #if !defined HAND && !defined HAND_WATER
            // Bias mutilplier, adjusts according to the current resolution and shadow depth view scale
            const vec3 biasFactor = vec3(shadowMapPixelSize, shadowMapPixelSize, 0.03125 * (shadowDistance * shadowMapPixelSize)) * 2.0;

            // Since we already have NLZ, we just need NLX and NLY to complete the shadow normal
            float NLX = dot(normal, vec3(shadowModelView[0].x, shadowModelView[1].x, shadowModelView[2].x));
            float NLY = dot(normal, vec3(shadowModelView[0].y, shadowModelView[1].y, shadowModelView[2].y));

            // Apply normal slope scaled bias. Bias in the z-axis is need to be applied to be scaled up
            shdPos += vec3(NLX, NLY, NLZ * shadowProjection[2].z) * (distortShape + 1.0) * biasFactor;
        #endif

        // Cave light leak fix
        float shdFactor = shdFade;

        #if defined PARALLAX_OCCLUSION && defined PARALLAX_SHADOW
            shdFactor *= parallaxShd;
        #endif

        #if defined TERRAIN || defined WATER
            if(isEyeInWater == 0) shdFactor *= min(1.0, (lmCoord.y + eyeBrightFact) * 4.0);
        #endif

        // Sample shadows, reduce whenever possible
        #ifdef SHADOW_FILTER
            #if ANTI_ALIASING >= 2
                float dither = fract(texelFetch(noisetex, ivec2(gl_FragCoord.xy) & 255, 0).x + frameFract);
            #else
                float dither = texelFetch(noisetex, ivec2(gl_FragCoord.xy) & 255, 0).x;
            #endif

            dither *= TAU;

            #ifdef SUBSURFACE_SCATTERING
                const float subSurfaceOffset = shadowDistanceInv;

                // Use more samples for subsurface scattering
                if(isSubSurface){
                    float subSurfaceFactor = isShadow ? max(ss - ss * NLZ * 16.0, 0.0) : ss;
                    float offSetSize = mix(shadowMapPixelSize, subSurfaceOffset, subSurfaceFactor);

                    vec3 shdCol = getShdCol(shdPos, dither, offSetSize, 4u);
                    float maxShdCol = maxOf(shdCol);
                    // return (max(pow(maxShdCol, subSurfaceFactor * 3.0), 0.0) * (shdFactor / (0.015625 + maxShdCol))) * shdCol;
                    return (mix(maxShdCol, cubed(maxShdCol), subSurfaceFactor) * (shdFactor / (0.015625 + maxShdCol))) * shdCol;
                }
            #endif

            #if ANTI_ALIASING >= 2
                return getShdCol(shdPos, dither, shadowMapPixelSize, 1u) * shdFactor;
            #else
                return getShdCol(shdPos, dither, shadowMapPixelSize, 2u) * shdFactor;
            #endif
        #else
            return getShdCol(shdPos) * shdFactor;
        #endif
    }
#endif

vec4 complexShadingForward(in dataPBR material){
    // Get block light squared
    float blockLightSquared = squared(lmCoord.x);
    // Get sky light squared
    float skyLightSquared = squared(lmCoord.y);

    // Calculate sky diffusion first, begining with the sky itself
    // Occlude the appled sky and thunder flash calculation by sky light amount
    vec3 totalIllumination = (toLinear(SKY_COLOR_DATA_BLOCK) + lightningFlash) * skyLightSquared;

    // Calculate ambient lightning
    // Kawwabi Added dimensional doors support
    #ifdef WORLD_BLOCK_GLOW
        #if WORLD_ID == -4 || WORLD_ID == -2
            // For world-4 private pockets and world-2 public/dungeon pockets: set to full brightness like night vision.
            totalIllumination = vec3(0.0);
            skyLightSquared = 0.0;
            blockLightSquared = 0.0;
            totalIllumination += toLinear(1.0);
        #else
            // For other dimensions with WORLD_BLOCK_GLOW: keep the original behavior.
            totalIllumination += toLinear(0.05);
        #endif
    #else
        totalIllumination += toLinear(AMBIENT_LIGHTING + nightVision * 0.5);
    #endif

    #if defined DIRECTIONAL_LIGHTMAPS && (defined TERRAIN || defined WATER)
        vec3 dirLightMapPos = fastNormalize(dFdx(vertexFeetPlayerPos) * dFdx(lmCoord.x) + dFdy(vertexFeetPlayerPos) * dFdy(lmCoord.x));
        float dirLightMap = min(1.0, max(0.0, dot(dirLightMapPos, material.normal)) * blockLightSquared * DIRECTIONAL_LIGHTMAP_STRENGTH + lmCoord.x);

        // Calculate block light
        #ifdef WORLD_WHITE_LIGHTING
            totalIllumination += toLinear((float(material.emissive == 0) * 0.25 + 1.0) * squared(dirLightMap) * vec3(1.0));
        #else
            totalIllumination += toLinear((float(material.emissive == 0) * 0.25 + 1.0) * squared(dirLightMap) * blockLightColor);
        #endif
    #else
        // Calculate block light
        #ifdef WORLD_WHITE_LIGHTING
            totalIllumination += toLinear((float(material.emissive == 0) * 0.25 + 1.0) * blockLightSquared * vec3(1.0));
        #else
            totalIllumination += toLinear((float(material.emissive == 0) * 0.25 + 1.0) * blockLightSquared * blockLightColor);
        #endif
    #endif

    // Apply baked ambient occlussion
    totalIllumination *= material.ambient;

    #ifdef WORLD_LIGHT
        // Get sRGB light color
        vec3 sRGBLightCol = LIGHT_COLOR_DATA_BLOCK0;

        // also equivalent to:
        // vec3(0, 0, 1) * mat3(shadowModelView) = vec3(shadowModelView[0].z, shadowModelView[1].z, shadowModelView[2].z)
        // shadowLightPosition is broken in other dimensions. The current is equivalent to:
        // (mat3(gbufferModelViewInverse) * shadowLightPosition + gbufferModelViewInverse[3].xyz) * 0.01
        float NLZ = dot(material.normal, vec3(shadowModelView[0].z, shadowModelView[1].z, shadowModelView[2].z));

        bool isShadow = NLZ > 0;
        bool isSubSurface = material.ss > 0;

        #ifdef SHADOW_MAPPING
            vec3 shdCol = vec3(0);

            // If the area isn't shaded, apply shadow mapping
            if(isShadow || isSubSurface) shdCol = getShdMapping(material.normal, NLZ, material.parallaxShd, material.ss, isShadow, isSubSurface);
        #else
            // Calculate fake shadows
            float shdCol = saturate(hermiteMix(0.9, 1.0, lmCoord.y)) * shdFade;

            #if defined PARALLAX_OCCLUSION && defined PARALLAX_SHADOW
                shdCol *= material.parallaxShd;
            #endif
        #endif

        float dirLight = isShadow ? NLZ : 0.0;

        #ifdef SUBSURFACE_SCATTERING
            // Diffuse with simple SS approximation
            if(isSubSurface) dirLight += (1.0 - dirLight) * material.ambient * material.ss;
        #endif

        #ifdef SHADOW_MAPPING
            vec3 finalShadowCol = shdCol * dirLight;
        #else
            float finalShadowCol = shdCol * dirLight;
        #endif

        #ifndef FORCE_DISABLE_WEATHER
            // Approximate rain diffusing light shadow
            float rainDiffuseAmount = rainStrength * 0.5;
            finalShadowCol *= 1.0 - rainDiffuseAmount;

            finalShadowCol += rainDiffuseAmount * material.ambient * skyLightSquared * (1.0 - shdFade);
        #endif

        // Calculate and add shadow diffuse
        totalIllumination += toLinear(sRGBLightCol) * finalShadowCol;
    #endif

    // Get view direction
    vec3 viewDir = -fastNormalize(vertexFeetPlayerPos);

    // Modified version of BSL's reflection PBR calculation
    // vec3 fresnel = (F0 + (1.0 - F0) * cosTheta) * smoothness
    // Fresnel calculation derived and optimized from this equation
    float NV = dot(material.normal, viewDir);
    float smoothCosTheta = NV > 0 ? exp2(-9.28 * NV) * material.smoothness : material.smoothness;
    float oneMinusCosTheta = material.smoothness - smoothCosTheta;

    if(material.metallic <= 0.9) totalIllumination *= 1.0 - (smoothCosTheta + material.metallic * oneMinusCosTheta);
    else totalIllumination *= 1.0 - material.smoothness;

    // Apply emissives
    totalIllumination += material.emissive * EMISSIVE_INTENSITY;

    vec4 totalLighting = vec4(material.albedo.rgb * totalIllumination, material.albedo.a);

    #if defined WORLD_LIGHT && defined SPECULAR_HIGHLIGHTS
        if(isShadow){
            // Get specular GGX
            vec3 specCol = getSpecularBRDF(viewDir, material.normal, material.albedo.rgb, NLZ, NV, material.metallic, material.smoothness) * shdCol;
            totalLighting.rgb += sunMoonIntensitySqrd * specCol * sRGBLightCol;
            if(material.albedo.a != 1) totalLighting.a = min(maxOf(specCol) + totalLighting.a, 1.0);
        }
    #endif

    return totalLighting;
}