vec3 complexShadingDeferred(vec3 sceneCol, vec3 screenPos, vec3 viewPos, vec3 normal, vec3 albedo, float viewDist, float metallic, float smoothness, vec3 dither){
	#if defined ROUGH_REFLECTIONS || defined SSGI
		vec3 noiseUnitVector = generateUnitVector(dither.xy);
	#endif
	
	// Calculate SSGI
	#ifdef SSGI
		// Get SSGI screen coordinates
		vec3 SSGIcoord = rayTraceScene(screenPos, viewPos, normalize(normal + noiseUnitVector), dither.z, SSGI_STEPS, SSGI_BISTEPS);

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

		float cosTheta = exp2(-9.0 * max(dot(normal, -nViewPos), 0.0));

		#ifdef ROUGH_REFLECTIONS
			// Rough the normals with noise
			normal = normalize(normal + noiseUnitVector * squared(1.0 - smoothness) * 0.5);
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

		// Modified version of BSL's reflection PBR calculation
		if(isMetal){
			vec3 fresnel = getFresnelSchlick(albedo, cosTheta) * smoothness;
			sceneCol = sceneCol * (1.0 - smoothness) + reflectCol * fresnel;
		}else{
			float fresnel = getFresnelSchlick(metallic, cosTheta) * smoothness;
			sceneCol = sceneCol * (1.0 - fresnel) + reflectCol * fresnel;
		}
	}

	return sceneCol;
}