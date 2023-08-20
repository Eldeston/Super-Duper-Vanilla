vec4 complexShadingGbuffers(in structPBR material){
	// Calculate sky diffusion first, begining with the sky itself
	vec3 totalDiffuse = toLinear(SKY_COL_DATA_BLOCK);

	#ifdef IS_IRIS
		// Calculate thunder flash
		totalDiffuse += lightningFlash;
	#endif

	// Get sky light squared
	float skyLightSquared = squared(lmCoord.y);
	// Occlude the appled sky and thunder flash calculation by sky light amount
	totalDiffuse *= skyLightSquared;

	#if defined DIRECTIONAL_LIGHTMAPS && (defined TERRAIN || defined WATER)
		vec3 dirLightMapCoord = dFdx(vertexPos.xyz) * dFdx(lmCoord.x) + dFdy(vertexPos.xyz) * dFdy(lmCoord.x);
		float dirLightMap = min(1.0, max(0.0, dot(fastNormalize(dirLightMapCoord), material.normal)) * lmCoord.x * DIRECTIONAL_LIGHTMAP_STRENGTH + lmCoord.x);

		// Calculate block light
		totalDiffuse += toLinear(dirLightMap * blockLightCol);
	#else
		// Calculate block light
		totalDiffuse += toLinear(lmCoord.x * blockLightCol);
	#endif

	// Lastly, calculate ambient lightning
	totalDiffuse += toLinear(AMBIENT_LIGHTING + nightVision * 0.5);

	// Apply baked ambient occlussion
	totalDiffuse *= material.ambient;

	#ifdef WORLD_LIGHT
		// Get sRGB light color
		vec3 sRGBLightCol = LIGHT_COL_DATA_BLOCK0;

		float NL = dot(material.normal, vec3(shadowModelView[0].z, shadowModelView[1].z, shadowModelView[2].z));
		// also equivalent to:
		// vec3(0, 0, 1) * mat3(shadowModelView) = vec3(shadowModelView[0].z, shadowModelView[1].z, shadowModelView[2].z)
    	// shadowLightPosition is broken in other dimensions. The current is equivalent to:
    	// (mat3(gbufferModelViewInverse) * shadowLightPosition + gbufferModelViewInverse[3].xyz) * 0.01

		bool isShadow = NL > 0;
		bool isSubSurface = material.ss > 0;

		float dirLight = isShadow ? NL : 0.0;

		#ifdef SUBSURFACE_SCATTERING
			// Diffuse with simple SS approximation
			if(isSubSurface) dirLight += (1.0 - dirLight) * material.ambient * material.ss * 0.5;
		#endif

		#if defined SHADOW_MAPPING && !defined ENTITIES_GLOWING
			vec3 shadowCol = vec3(0);

			// If the area isn't shaded, apply shadow mapping
			if(isShadow || isSubSurface){
				// Get shadow pos
				vec3 shdPos = vec3(shadowProjection[0].x, shadowProjection[1].y, shadowProjection[2].z) * (mat3(shadowModelView) * vertexPos.xyz + shadowModelView[3].xyz);
				shdPos.z += shadowProjection[3].z;

				// Apply shadow distortion and transform to shadow screen space
				shdPos = vec3(shdPos.xy / (length(shdPos.xy) * 2.0 + 0.2), shdPos.z * 0.1) + 0.5;
				// Bias mutilplier, adjusts according to the current resolution
				const vec3 biasAdjustMult = vec3(2, 2, -0.0625) / shadowMapResolution;

				// Get shadow normal from vertex normal
				vec3 shdNormal = mat3(shadowModelView) * TBN[2];
				// Apply normal bias
				shdPos += shdNormal * biasAdjustMult;

				// Sample shadows
				#ifdef SHADOW_FILTER
					#if ANTI_ALIASING >= 2
						float blueNoise = toRandPerFrame(texelFetch(noisetex, ivec2(gl_FragCoord.xy) & 255, 0).x, frameTimeCounter);
					#else
						float blueNoise = texelFetch(noisetex, ivec2(gl_FragCoord.xy) & 255, 0).x;
					#endif

					shadowCol = getShdCol(shdPos, blueNoise * TAU);
				#else
					shadowCol = getShdCol(shdPos);
				#endif

				// Cave light leak fix
				float caveFixShdFactor = shdFade;
				if(isEyeInWater == 0) caveFixShdFactor *= min(1.0, lmCoord.y * 2.0 + eyeBrightFact);
				
				#if defined PARALLAX_OCCLUSION && defined PARALLAX_SHADOWS
					shadowCol *= material.parallaxShd * caveFixShdFactor;
				#else
					shadowCol *= caveFixShdFactor;
				#endif
			}
		#else
			// Sample fake shadows
			float shadowCol = saturate(hermiteMix(0.96, 0.98, lmCoord.y)) * shdFade;

			#if defined PARALLAX_OCCLUSION && defined PARALLAX_SHADOWS
				shadowCol *= material.parallaxShd;
			#endif
		#endif

		#ifndef FORCE_DISABLE_WEATHER
			// Approximate rain diffusing light shadow
			float rainDiffuseAmount = rainStrength * 0.5;
			shadowCol *= 1.0 - rainDiffuseAmount;

			shadowCol += rainDiffuseAmount * material.ambient * skyLightSquared;
		#endif
		
		// Calculate and add shadow diffuse
		totalDiffuse += toLinear(sRGBLightCol) * shadowCol * dirLight;
	#endif

	totalDiffuse = material.albedo.rgb * (totalDiffuse + material.emissive * EMISSIVE_INTENSITY);

	#ifdef WORLD_LIGHT
		if(isShadow){
			// Get specular GGX
			vec3 specCol = getSpecBRDF(fastNormalize(-vertexPos.xyz), vec3(shadowModelView[0].z, shadowModelView[1].z, shadowModelView[2].z), material.normal, material.albedo.rgb, NL, material.metallic, 1.0 - material.smoothness);
			// Needs to multiplied twice in order for the speculars to look relatively "correct"
			#ifdef FORCE_DISABLE_WEATHER
				totalDiffuse += min(vec3(SUN_MOON_INTENSITY * SUN_MOON_INTENSITY), specCol) * (1.0 + material.smoothness) * sRGBLightCol * shadowCol;
			#else
				totalDiffuse += min(vec3(SUN_MOON_INTENSITY * SUN_MOON_INTENSITY), specCol) * (1.0 + material.smoothness) * (1.0 - rainStrength) * sRGBLightCol * shadowCol;
			#endif
		}
	#endif

	return vec4(totalDiffuse, material.albedo.a);
}