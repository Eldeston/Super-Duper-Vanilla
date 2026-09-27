#if WORLD_ID == 1
	#ifndef END_FLASH_UNIFORM_DECLARED
		#define END_FLASH_UNIFORM_DECLARED
		uniform float endFlashIntensity;
	#endif
#endif

vec3 basicShadingForward(in vec3 albedo){
	// Get sky light squared
	float skyLightSquared = squared(lmCoord.y);

	#ifndef FORCE_DISABLE_WEATHER
		vec3 linearSkyCol = mix(toLinear(SKY_COLOR_DATA_BLOCK), vec3(dot(toLinear(fogColor), vec3(0.2126, 0.7152, 0.0722))), weatherFade);
	#else
		vec3 linearSkyCol = toLinear(SKY_COLOR_DATA_BLOCK);
	#endif

	// Calculate sky diffusion first, begining with the sky itself
	// Occlude the appled sky and thunder flash calculation by sky light amount
	vec3 totalDiffuse = (linearSkyCol + lightningFlash) * skyLightSquared;

	#if WORLD_ID == 1
		totalDiffuse += toLinear(vec3(0.20, 0.12, 0.28)) * (endFlashIntensity * skyLightSquared);
		#ifdef END_BH_LIGHT
			if(END_BH_LIGHT > 0.0) totalDiffuse += toLinear(LIGHT_COLOR_DATA_BLOCK0 * (END_BH_LIGHT * 0.5)) * skyLightSquared;
		#endif
	#endif

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
			float rainDirectAmount = 1.0 - weatherFade * (1.0 - WEATHER_DIRECT_LIGHT);
			shdCol *= rainDirectAmount;

			float rainDiffuseAmount = weatherFade * WEATHER_DIRECT_LIGHT;
			shdCol += rainDiffuseAmount * skyLightSquared;
		#endif

		#if WORLD_ID == 1
			vec3 sRGBLightCol = (LIGHT_COLOR_DATA_BLOCK0 * 1.5 + vec3(0.3, 0.1, 0.4)) * endFlashIntensity;
			totalDiffuse += shdCol * toLinear(sRGBLightCol);
		#else
			// Calculate and add shadow diffuse
			totalDiffuse += shdCol * toLinear(LIGHT_COLOR_DATA_BLOCK0);
		#endif
	#endif

	// Return final result
	return albedo.rgb * totalDiffuse;
}