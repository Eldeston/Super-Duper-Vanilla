vec3 complexShadingDeferred(vec3 sceneCol, vec3 screenPos, vec3 viewPos, vec3 normal, vec3 albedo, float viewDist, float metallic, float smoothness, vec3 dither){
	#if defined SSGI || defined SSR
		// Get model view normal
		normal = mat3(gbufferModelView) * normal;
	#endif

	// Calculate SSGI
	#ifdef SSGI
		// Get SSGI screen coordinates
		vec3 SSGIcoord = rayTraceScene(screenPos, viewPos, normalize(normal + generateUnitVector(dither.xy)), dither.z, SSGI_STEPS, SSGI_BISTEPS);

		// If sky don't do SSGI
		#ifdef PREVIOUS_FRAME
			if(SSGIcoord.z > 0.5) sceneCol += albedo * texture2DLod(colortex5, toPrevScreenPos(SSGIcoord.xy), 0).rgb;
		#else
			if(SSGIcoord.z > 0.5) sceneCol += albedo * texture2DLod(gcolor, SSGIcoord.xy, 0).rgb;
		#endif
	#endif

	// If smoothness is 0, don't do reflections
	if(smoothness > 0.005){
		bool isMetal = metallic > 0.9;

		vec3 nViewPos = viewPos / viewDist;

		// Get fresnel
		vec3 fresnel = getFresnelSchlick(max(dot(normal, -nViewPos), 0.0),
			isMetal ? albedo : vec3(metallic)) * smoothness;

		// Calculate SSR and sky reflections
		#ifdef SSR
			#ifdef ROUGH_REFLECTIONS
				// Rough the normals with noise
				normal = normalize(normal + (dither - 0.5) * squared(1.0 - smoothness) * 0.8);
			#endif

		// Get reflected view direction
		vec3 reflectedViewDir = reflect(nViewPos, normal);

		// Calculate SSR and sky reflections
		#ifdef SSR
			// Get SSR screen coordinates
			vec3 SSRCoord = rayTraceScene(screenPos, viewPos, reflectedViewDir, dither.z, SSR_STEPS, SSR_BISTEPS);
			
			#ifdef PREVIOUS_FRAME
				// Get reflections and check for sky
				vec3 reflectCol = SSRCoord.z < 0.5 ? getSkyRender(mat3(gbufferModelViewInverse) * reflectedViewDir, true, true) : texture2DLod(colortex5, toPrevScreenPos(SSRCoord.xy), 0).rgb;
			#else
				// Get reflections and check for sky
				vec3 reflectCol = SSRCoord.z < 0.5 ? getSkyRender(mat3(gbufferModelViewInverse) * reflectedViewDir, true, true) : texture2DLod(gcolor, SSRCoord.xy, 0).rgb;
			#endif
		#else
			vec3 reflectCol = getSkyRender(mat3(gbufferModelViewInverse) * reflectedViewDir, true, true);
		#endif

		// Simplified and modified version of BSL's reflection PBR calculation
		sceneCol *= isMetal ? vec3(1.0 - smoothness) : 1.0 - fresnel;
		sceneCol += reflectCol * fresnel;
	}

	return sceneCol;
}