vec4 simpleShadingGbuffers(in vec4 albedo){
	// Calculate sky diffusion first, begining with the sky itself
	vec3 totalDiffuse = toLinear(SKY_COL_DATA_BLOCK);

	#ifdef IS_IRIS
		// Calculate thunder flash
		totalDiffuse += lightningFlash;
	#endif

	#ifndef CLOUDS
		// Get sky light squared
		float skyLightSquared = squared(lmCoord.y);
		// Occlude the appled sky and thunder flash calculation by sky light amount
		totalDiffuse *= skyLightSquared;

		// Calculate block light
		totalDiffuse += toLinear(lmCoord.x * blockLightCol);
	#endif

	// Lastly, calculate ambient lightning
	totalDiffuse += toLinear(nightVision * 0.5 + AMBIENT_LIGHTING);

	#ifdef WORLD_LIGHT
		#ifdef SHADOW_MAPPING
			// Get shadow pos
			vec3 shdPos = vec3(shadowProjection[0].x, shadowProjection[1].y, shadowProjection[2].z) * (mat3(shadowModelView) * vertexPos.xyz + shadowModelView[3].xyz);
			shdPos.z += shadowProjection[3].z;

			// Apply shadow distortion and transform to shadow screen space
			shdPos = vec3(shdPos.xy / (length(shdPos.xy) * 2.0 + 0.2), shdPos.z * 0.1) + 0.5;

			#ifdef CLOUDS
				// Bias mutilplier, adjusts according to the current shadow resolution
				const vec3 biasAdjustMult = vec3(2, 2, -0.0625) / shadowMapResolution;

				vec3 shdNormal = mat3(shadowModelView) * vertexNormal;
				// Apply normal bias for clouds
				shdPos += shdNormal * biasAdjustMult;
			#else
				// Bias mutilplier, adjusts according to the current shadow resolution
				const float biasAdjustMult = 2.0 / shadowMapResolution;

				// Apply normal bias for particles and basic
				shdPos.y += shadowModelView[1].y * biasAdjustMult;
			#endif

			// Sample shadows
			#ifdef SHADOW_FILTER
				#if ANTI_ALIASING >= 2
					float blueNoise = toRandPerFrame(texelFetch(noisetex, ivec2(gl_FragCoord.xy) & 255, 0).x, frameTimeCounter);
				#else
					float blueNoise = texelFetch(noisetex, ivec2(gl_FragCoord.xy) & 255, 0).x;
				#endif

				vec3 shadowCol = getShdCol(shdPos, blueNoise * TAU);
			#else
				vec3 shadowCol = getShdCol(shdPos);
			#endif

			#ifdef CLOUDS
				// Apply simple diffuse for clouds
				shadowCol *= max(0.0, dot(vertexNormal, vec3(shadowModelView[0].z, shadowModelView[1].z, shadowModelView[2].z)) * 0.6 + 0.4) * shdFade;
			#else
				// Cave light leak fix
				float caveFixShdFactor = shdFade;
				if(isEyeInWater == 0) caveFixShdFactor *= min(1.0, lmCoord.y * 2.0 + eyeBrightFact);

				shadowCol *= caveFixShdFactor;
			#endif
		#else
			#ifdef CLOUDS
				// Apply simple diffuse for clouds
				float shadowCol = max(0.0, dot(vertexNormal, vec3(shadowModelView[0].z, shadowModelView[1].z, shadowModelView[2].z)) * 0.6 + 0.4) * shdFade;
			#else
				// Sample fake shadows
				float shadowCol = saturate(hermiteMix(0.96, 0.98, lmCoord.y)) * shdFade;
			#endif
		#endif

		#ifndef FORCE_DISABLE_WEATHER
			// Approximate rain diffusing light shadow
			float rainDiffuseAmount = rainStrength * 0.5;
			shadowCol *= 1.0 - rainDiffuseAmount;

			#ifdef CLOUDS
				shadowCol += rainDiffuseAmount;
			#else
				shadowCol += rainDiffuseAmount * skyLightSquared;
			#endif
		#endif

		// Calculate and add shadow diffuse
		totalDiffuse += shadowCol * toLinear(LIGHT_COL_DATA_BLOCK0);
	#endif

	// Return final result
	return vec4(albedo.rgb * totalDiffuse, albedo.a);
}