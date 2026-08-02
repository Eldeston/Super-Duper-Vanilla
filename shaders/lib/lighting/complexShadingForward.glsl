vec3 complexShadingForward(in dataPBR material){
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

		float NLZ = dot(material.normal, vec3(shadowModelView[0].z, shadowModelView[1].z, shadowModelView[2].z));
		// also equivalent to:
		// vec3(0, 0, 1) * mat3(shadowModelView) = vec3(shadowModelView[0].z, shadowModelView[1].z, shadowModelView[2].z)
    	// shadowLightPosition is broken in other dimensions. The current is equivalent to:
    	// (mat3(gbufferModelViewInverse) * shadowLightPosition + gbufferModelViewInverse[3].xyz) * 0.01

		bool isShadow = NLZ > 0;
		bool isSubSurface = material.ss > 0;

		#if defined SHADOW_MAPPING && !defined DH_GBUFFERS
			vec3 shdCol = vec3(0);

			// If the area isn't shaded, apply shadow mapping
			if(isShadow || isSubSurface){
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
				shdPos = vec3(shdPos.xy / (length(shdPos.xy) * 2.0 + 0.2), shdPos.z * 0.1) + 0.5;

				// Items that are not subject to depth do not need a bias
				#if !defined HAND && !defined HAND_WATER
					// Bias mutilplier, adjusts according to the current resolution
					// The Z is instead a constant and the only extra bias that isn't accounted for is shadow distortion "blobs"
					// 0.00006103515625 = exp2(-14)
					const vec3 biasAdjustFactor = vec3(shadowMapPixelSize * 2.0, shadowMapPixelSize * 2.0, -0.00006103515625);

					// Since we already have NLZ, we just need NLX and NLY to complete the shadow normal
					float NLX = dot(material.normal, vec3(shadowModelView[0].x, shadowModelView[1].x, shadowModelView[2].x));
					float NLY = dot(material.normal, vec3(shadowModelView[0].y, shadowModelView[1].y, shadowModelView[2].y));

					// Apply normal based bias
					shdPos += vec3(NLX, NLY, NLZ) * biasAdjustFactor;
				#endif

				// Sample shadows
				#ifdef SHADOW_FILTER
					#if ANTI_ALIASING >= 2
						float dither = fract(texelFetch(noisetex, ivec2(gl_FragCoord.xy) & 255, 0).x + frameFract);
					#else
						float dither = texelFetch(noisetex, ivec2(gl_FragCoord.xy) & 255, 0).x;
					#endif

					shdCol = getShdCol(shdPos, dither * TAU);
				#else
					shdCol = getShdCol(shdPos);
				#endif

				// Cave light leak fix
				float shdFactor = shdFade;

				#if defined PARALLAX_OCCLUSION && defined PARALLAX_SHADOW
					shdFactor *= material.parallaxShd;
				#endif

				#if defined TERRAIN || defined WATER
					if(isEyeInWater == 0) shdFactor *= min(1.0, (lmCoord.y + eyeBrightFact) * 4.0);
				#endif

				shdCol *= shdFactor;
			}
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
			if(isSubSurface) dirLight += (1.0 - dirLight) * material.ambient * material.ss * 0.5;
		#endif

		shdCol *= dirLight;

		#ifndef FORCE_DISABLE_WEATHER
			// Approximate rain diffusing light shadow
			float rainDiffuseAmount = rainStrength * 0.5;
			shdCol *= 1.0 - rainDiffuseAmount;

			shdCol += rainDiffuseAmount * material.ambient * skyLightSquared * (1.0 - shdFade);
		#endif

		// Calculate and add shadow diffuse
		totalIllumination += toLinear(sRGBLightCol) * shdCol;
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
	else{ totalIllumination *= 1.0 - material.smoothness; }

	// Apply emissives
	totalIllumination += material.emissive * EMISSIVE_INTENSITY;

	vec3 totalLighting = material.albedo.rgb * totalIllumination;

	#if defined WORLD_LIGHT && defined SPECULAR_HIGHLIGHTS
		if(isShadow){
			// Get specular GGX
			vec3 specCol = getSpecularBRDF(viewDir, material.normal, material.albedo.rgb, NLZ, NV, material.metallic, material.smoothness);
			totalLighting += specCol * shdCol * sRGBLightCol;
		}
	#endif

	return totalLighting;
}