vec4 simpleShadingGbuffers(in vec4 albedo){
	#ifdef CLOUDS
		// Calculate total diffuse for clouds
		vec3 totalDiffuse = toLinear(SKY_COL_DATA_BLOCK) +
			toLinear(AMBIENT_LIGHTING + nightVision * 0.5);
	#else
		// Calculate total diffuse
		vec3 totalDiffuse = toLinear(SKY_COL_DATA_BLOCK * lmCoord.y) +
			toLinear((lmCoord.x * BLOCKLIGHT_I * 0.00392156863) * vec3(BLOCKLIGHT_R, BLOCKLIGHT_G, BLOCKLIGHT_B)) +
			toLinear(AMBIENT_LIGHTING + nightVision * 0.5);
	#endif

	#ifdef WORLD_LIGHT
		#ifdef CLOUDS
			float NL = max(0.0, dot(vertexNormal, vec3(shadowModelView[0].z, shadowModelView[1].z, shadowModelView[2].z)) * 0.6 + 0.4);
		#else
			float NL = dot(vertexNormal, vec3(shadowModelView[0].z, shadowModelView[1].z, shadowModelView[2].z));
		#endif

		float rainDiffuseAmount = rainStrength * 0.5;

		#ifdef SHD_ENABLE
			vec3 shadowCol = vec3(0);

			// If the area isn't shaded, apply shadow mapping
			if(NL > 0){
				// Get shadow pos
				vec3 shdPos = vec3(shadowProjection[0].x, shadowProjection[1].y, shadowProjection[2].z) * (mat3(shadowModelView) * vertexPos.xyz + shadowModelView[3].xyz) + shadowProjection[3].xyz;

				// Bias mutilplier, adjusts according to the current shadow distance and resolution
				const float biasAdjustMult = log2(max(4.0, shadowDistance - shadowMapResolution * 0.125)) * 0.25;
				float distortFactor = getDistortFactor(shdPos.xy);

				// Apply bias according to normal in shadow space
				shdPos += vec3(shadowProjection[0].x, shadowProjection[1].y, shadowProjection[2].z) * (mat3(shadowModelView) * vertexNormal) * distortFactor * biasAdjustMult;
				shdPos = distort(shdPos, distortFactor) * 0.5 + 0.5;

				// Sample shadows
				#ifdef SHD_FILTER
					#if ANTI_ALIASING >= 2
						shadowCol = getShdCol(shdPos, toRandPerFrame(texelFetch(noisetex, ivec2(gl_FragCoord.xy) & 255, 0).x, frameTimeCounter) * TAU);
					#else
						shadowCol = getShdCol(shdPos, texelFetch(noisetex, ivec2(gl_FragCoord.xy) & 255, 0).x * TAU);
					#endif
				#else
					shadowCol = getShdCol(shdPos);
				#endif

				#ifndef CLOUDS
					// Cave light leak fix
					if(isEyeInWater != 1) shadowCol *= min(1.0, lmCoord.y * 2.0) * (1.0 - eyeBrightFact) + eyeBrightFact;
				#endif
			}

			#ifdef CLOUDS
				// Apply simple diffuse for clouds
				shadowCol *= NL;
			#endif
		#else
			#ifdef CLOUDS
				// Apply simple diffuse for clouds
				float shadowCol = NL;
			#else
				// Sample fake shadows
				float shadowCol = smoothstep(0.94, 0.96, lmCoord.y);
			#endif
		#endif

		#ifdef CLOUDS
			// Calculate and add shadow diffuse
			totalDiffuse += (shadowCol * shdFade * (1.0 - rainDiffuseAmount) + rainDiffuseAmount) * toLinear(LIGHT_COL_DATA_BLOCK);
		#else
			// Calculate and add shadow diffuse
			totalDiffuse += (shadowCol * shdFade * (1.0 - rainDiffuseAmount) + lmCoord.y * lmCoord.y * rainDiffuseAmount) * toLinear(LIGHT_COL_DATA_BLOCK);
		#endif
	#endif

	// Return final result
	return vec4(albedo.rgb * totalDiffuse, albedo.a);
}