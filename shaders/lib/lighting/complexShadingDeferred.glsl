vec3 complexShadingDeferred(in vec3 sceneCol, in vec3 screenPos, in vec3 viewPos, in vec3 normal, in vec3 albedo, in float viewDotInvSqrt, in float metallic, in float smoothness, in vec3 dither){
	#if defined ROUGH_REFLECTIONS || defined SSGI
		vec3 noiseUnitVector = generateUnitVector(dither.xy);
	#endif

	// Calculate SSGI
	#ifdef SSGI
		// Get SSGI screen coordinates
		vec3 SSGIcoord = rayTraceScene(screenPos, viewPos, generateCosineVector(normal, noiseUnitVector), dither.z);

		// If sky don't do SSGI
		#ifdef PREVIOUS_FRAME
			if(SSGIcoord.z > 0.5) sceneCol += albedo * textureLod(colortex5, getPrevScreenCoord(SSGIcoord.xy), 0).rgb;
		#else
			if(SSGIcoord.z > 0.5) sceneCol += albedo * textureLod(gcolor, SSGIcoord.xy, 0).rgb;
		#endif
	#endif

	// If smoothness is 0, return immediately
	if(smoothness < 0.005) return sceneCol;

	vec3 nViewPos = viewPos * viewDotInvSqrt;

	#ifdef ROUGH_REFLECTIONS
		// Rough the normals with noise
		normal = generateCosineVector(normal, noiseUnitVector * (squared(1.0 - smoothness) * 0.5));
	#endif

	// Get reflected view direction
	// reflect(direction, normal) = direction - 2.0 * dot(normal, direction) * normal
	float NV = dot(normal, -nViewPos);
	vec3 reflectViewDir = nViewPos + (2.0 * NV) * normal;

	// Calculate SSR and sky reflections
	#ifdef SSR
		// Get SSR screen coordinates
		vec3 SSRCoord = rayTraceScene(screenPos, viewPos, reflectViewDir, dither.z);

		#ifdef PREVIOUS_FRAME
			// Get reflections and check for sky
			vec3 reflectCol = SSRCoord.z < 0.5 ? getSkyReflection(reflectViewDir) : textureLod(colortex5, getPrevScreenCoord(SSRCoord.xy), 0).rgb;
		#else
			// Get reflections and check for sky
			vec3 reflectCol = SSRCoord.z < 0.5 ? getSkyReflection(reflectViewDir) : textureLod(gcolor, SSRCoord.xy, 0).rgb;
		#endif
	#else
		vec3 reflectCol = getSkyReflection(reflectViewDir);
	#endif

	// Modified version of BSL's reflection PBR calculation
	// vec3 fresnel = (F0 + (1.0 - F0) * cosTheta) * smoothness
	// Fresnel calculation derived and optimized from this equation
	float smoothCosTheta = NV > 0 ? exp2(-9.28 * NV) * smoothness : smoothness;
	float oneMinusCosTheta = smoothness - smoothCosTheta;

	if(metallic <= 0.9) return sceneCol + (reflectCol - sceneCol) * (smoothCosTheta + metallic * oneMinusCosTheta);
	return sceneCol * (1.0 - smoothness) + reflectCol * (smoothCosTheta + albedo * oneMinusCosTheta);
}