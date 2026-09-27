vec3 basicShadingForward(in vec3 albedo){
	// Get sky light squared
	float skyLightSquared = squared(lmCoord.y);

	#ifndef FORCE_DISABLE_WEATHER
		vec3 linearSkyCol = mix(toLinear(SKY_COLOR_DATA_BLOCK), vec3(dot(toLinear(fogColor), vec3(0.2126, 0.7152, 0.0722))), rainStrength);
	#else
		vec3 linearSkyCol = toLinear(SKY_COLOR_DATA_BLOCK);
	#endif

	// Calculate sky diffusion first, begining with the sky itself
	// Occlude the appled sky and thunder flash calculation by sky light amount
	vec3 totalDiffuse = (linearSkyCol + lightningFlash) * skyLightSquared;

	// Calculate block light
	totalDiffuse += toLinear(squared(lmCoord.x) * blockLightColor * 1.25);

	// Calculate ambient lightning
	totalDiffuse += toLinear(nightVision * 0.5 + AMBIENT_LIGHTING);

	#ifdef WORLD_LIGHT
		#ifdef SHADOW_MAPPING
			// Apply shadow distortion and transform to shadow screen space
			vec3 shdPos = vec3(vertexShdPos.xy / (length(vertexShdPos.xy) * 2.0 + 0.2) + 0.5, vertexShdPos.z);

			// Sample shadows
			#ifdef SHADOW_FILTER
				#if ANTI_ALIASING >= 2
					float dither = fract(texelFetch(noisetex, ivec2(gl_FragCoord.xy) & 255, 0).x + frameFract);
				#else
					float dither = texelFetch(noisetex, ivec2(gl_FragCoord.xy) & 255, 0).x;
				#endif

				vec3 shdCol = getShdCol(shdPos, dither * TAU);
			#else
				vec3 shdCol = getShdCol(shdPos);
			#endif

			shdCol *= shdFade;
		#else
			// Sample fake shadows
			float shdCol = saturate(hermiteMix(0.9, 1.0, lmCoord.y)) * shdFade;
		#endif

		#ifndef FORCE_DISABLE_WEATHER
			// Approximate rain diffusing light shadow
			float rainDirectAmount = 1.0 - rainStrength * (1.0 - WEATHER_DIRECT_LIGHT);
			shdCol *= rainDirectAmount;

			float rainDiffuseAmount = rainStrength * WEATHER_DIRECT_LIGHT;
			shdCol += rainDiffuseAmount * skyLightSquared;
		#endif

		// Calculate and add shadow diffuse
		totalDiffuse += shdCol * toLinear(LIGHT_COLOR_DATA_BLOCK0);
	#endif

	// Return final result
	return albedo.rgb * totalDiffuse;
}