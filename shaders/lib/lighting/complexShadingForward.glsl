#if WORLD_ID == 1
	#ifndef END_FLASH_UNIFORM_DECLARED
		#define END_FLASH_UNIFORM_DECLARED
		uniform float endFlashIntensity;
	#endif
#endif

vec3 complexShadingForward(in dataPBR material){
	// Get block light squared
	float blockLightSquared = squared(lmCoord.x);
	// Get sky light squared
	float skyLightSquared = squared(lmCoord.y);

	#ifndef FORCE_DISABLE_WEATHER
		vec3 linearSkyCol = mix(toLinear(SKY_COLOR_DATA_BLOCK), vec3(dot(toLinear(fogColor), vec3(0.2126, 0.7152, 0.0722))), weatherFade);
	#else
		vec3 linearSkyCol = toLinear(SKY_COLOR_DATA_BLOCK);
	#endif

	// Calculate sky diffusion first, begining with the sky itself
	// Occlude the appled sky and thunder flash calculation by sky light amount
	vec3 totalIllumination = (linearSkyCol + lightningFlash) * skyLightSquared;

	#if WORLD_ID == 1
		totalIllumination += toLinear(vec3(0.12, 0.08, 0.16) * endFlashIntensity);
	#endif

	// Calculate ambient lightning
	totalIllumination += toLinear(AMBIENT_LIGHTING + nightVision * 0.5);

	#if defined DIRECTIONAL_LIGHTMAPS && (defined TERRAIN || defined WATER)
		vec3 dirLightMapPos = fastNormalize(dFdx(vertexFeetPlayerPos) * dFdx(lmCoord.x) + dFdy(vertexFeetPlayerPos) * dFdy(lmCoord.x));
		float dirLightMap = min(1.0, max(0.0, dot(dirLightMapPos, material.normal)) * blockLightSquared * DIRECTIONAL_LIGHTMAP_STRENGTH + lmCoord.x);

		// Calculate block light
		totalIllumination += toLinear((float(material.emissive == 0) * 0.25 + 1.0) * squared(dirLightMap) * blockLightColor);
	#else
		// Calculate block light
		totalIllumination += toLinear((float(material.emissive == 0) * 0.25 + 1.0) * blockLightSquared * blockLightColor);
	#endif

	// Apply baked ambient occlussion
	totalIllumination *= material.ambient;

	#ifdef WORLD_LIGHT
		#if WORLD_ID == 1
			vec3 sRGBLightCol = (LIGHT_COLOR_DATA_BLOCK0 * 1.5 + vec3(0.3, 0.1, 0.4)) * endFlashIntensity;
		#else
			// Get sRGB light color
			vec3 sRGBLightCol = LIGHT_COLOR_DATA_BLOCK0;
		#endif

		float NLZ = dot(material.normal, vec3(shadowModelView[0].z, shadowModelView[1].z, shadowModelView[2].z));
		bool isShadow = NLZ > 0;
		bool isSubSurface = material.ss > 0;

		#if defined SHADOW_MAPPING && !defined DH_GBUFFERS
			vec3 shdCol = vec3(0);

			// If the area isn't shaded, apply shadow mapping
			if(isShadow || isSubSurface){
				vec3 feetPlayerPos = vertexFeetPlayerPos;

				#ifdef ENTITIES
					// Fixes boats having water shadows inside them
					if(entityId == 10133) feetPlayerPos.y += 0.2;
				#endif

				// Get shadow pos
				vec3 shdPos = vec3(shadowProjection[0].x, shadowProjection[1].y, shadowProjection[2].z) * (mat3(shadowModelView) * feetPlayerPos + shadowModelView[3].xyz);
				shdPos.z += shadowProjection[3].z;

				// Apply shadow distortion and transform to shadow screen space
				shdPos = vec3(shdPos.xy / (length(shdPos.xy) * 2.0 + 0.2), shdPos.z * 0.1) + 0.5;

				#if !defined HAND && !defined HAND_WATER
					const vec3 biasAdjustFactor = vec3(shadowMapPixelSize * 2.0, shadowMapPixelSize * 2.0, -0.00006103515625);
					float NLX = dot(material.normal, vec3(shadowModelView[0].x, shadowModelView[1].x, shadowModelView[2].x));
					float NLY = dot(material.normal, vec3(shadowModelView[0].y, shadowModelView[1].y, shadowModelView[2].y));
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
			float rainDirectAmount = 1.0 - weatherFade * (1.0 - WEATHER_DIRECT_LIGHT);
			shdCol *= rainDirectAmount;

			float rainDiffuseAmount = weatherFade * WEATHER_DIRECT_LIGHT;
			shdCol += rainDiffuseAmount * material.ambient * skyLightSquared * (1.0 - shdFade);
		#endif

		// Calculate and add shadow diffuse
		totalIllumination += toLinear(sRGBLightCol) * shdCol;
	#endif

	// Get view direction
	vec3 viewDir = -fastNormalize(vertexFeetPlayerPos);

	// Calculate reflection PBR factor
	float NV = dot(material.normal, viewDir);
	float smoothCosTheta = NV > 0 ? exp2(-9.28 * NV) * material.smoothness : material.smoothness;
	float oneMinusCosTheta = material.smoothness - smoothCosTheta;

	if(material.metallic <= 0.9) totalIllumination *= 1.0 - (smoothCosTheta + material.metallic * oneMinusCosTheta);
	else totalIllumination *= 1.0 - material.smoothness;

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