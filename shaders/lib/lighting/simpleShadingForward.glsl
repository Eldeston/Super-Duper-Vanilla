vec4 simpleShadingGbuffers(in vec4 albedo){
	#ifdef CLOUDS
		// Calculate total diffuse for clouds
		vec3 totalDiffuse = toLinear(SKY_COL_DATA_BLOCK) + toLinear(nightVision * 0.5 + AMBIENT_LIGHTING);
	#else
		// Calculate total diffuse
		vec3 totalDiffuse = toLinear(SKY_COL_DATA_BLOCK * lmCoord.y) + toLinear(nightVision * 0.5 + AMBIENT_LIGHTING) +
			toLinear((lmCoord.x * BLOCKLIGHT_I * 0.00392156863) * vec3(BLOCKLIGHT_R, BLOCKLIGHT_G, BLOCKLIGHT_B));
	#endif

	// Thunder flash
	#ifdef CLOUDS
		totalDiffuse += toLinear(lightningFlash) * EMISSIVE_INTENSITY;
	#else
		totalDiffuse += toLinear(lightningFlash * lmCoord.y) * EMISSIVE_INTENSITY;
	#endif

	#ifdef WORLD_LIGHT
		#ifdef SHADOW
			// Get shadow pos
			vec3 shdPos = vec3(shadowProjection[0].x, shadowProjection[1].y, shadowProjection[2].z) * (mat3(shadowModelView) * vertexPos.xyz + shadowModelView[3].xyz) + shadowProjection[3].xyz;

			// Bias mutilplier, adjusts according to the current shadow distance and resolution
			const float biasAdjustMult = (shadowDistance / shadowMapResolution) * 4.0;
			float distortFactor = getDistortFactor(shdPos.xy);

			#ifdef CLOUDS
				// Apply bias according to normal in shadow space for clouds
				shdPos += vec3(shadowProjection[0].x, shadowProjection[1].y, shadowProjection[2].z) * (mat3(shadowModelView) * vertexNormal) * distortFactor * biasAdjustMult;
			#else
				// Apply simpler bias for particles and basic
				shdPos.y += shadowProjection[1].y * shadowModelView[1].y * distortFactor * biasAdjustMult;
			#endif

			shdPos = distort(shdPos, distortFactor) * 0.5 + 0.5;

			// Sample shadows
			#ifdef SHADOW_FILTER
				#if ANTI_ALIASING >= 2
					vec3 shadowCol = getShdCol(shdPos, toRandPerFrame(texelFetch(noisetex, ivec2(gl_FragCoord.xy) & 255, 0).x, frameTimeCounter) * TAU);
				#else
					vec3 shadowCol = getShdCol(shdPos, texelFetch(noisetex, ivec2(gl_FragCoord.xy) & 255, 0).x * TAU);
				#endif
			#else
				vec3 shadowCol = getShdCol(shdPos);
			#endif

			#ifdef CLOUDS
				// Apply simple diffuse for clouds
				shadowCol *= max(0.0, dot(vertexNormal, vec3(shadowModelView[0].z, shadowModelView[1].z, shadowModelView[2].z)) * 0.6 + 0.4) * shdFade;
			#else
				// Cave light leak fix
				shadowCol *= isEyeInWater == 1 ? shdFade : (min(1.0, lmCoord.y * 2.0) * (1.0 - eyeBrightFact) + eyeBrightFact) * shdFade;
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
				shadowCol += rainDiffuseAmount * lmCoord.y * lmCoord.y;
			#endif
		#endif

		// Calculate and add shadow diffuse
		totalDiffuse += shadowCol * toLinear(LIGHT_COL_DATA_BLOCK0);
	#endif

	// Return final result
	return vec4(albedo.rgb * totalDiffuse, albedo.a);
}