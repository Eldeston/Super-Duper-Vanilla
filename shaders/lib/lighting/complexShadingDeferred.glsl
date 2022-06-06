vec3 complexShadingDeferred(vec3 sceneCol, vec3 skyCol, vec3 lightCol, vec3 screenPos, vec3 viewPos, vec3 eyePlayerPos, vec3 normal, vec3 albedo, float metallic, float smoothness, vec3 dither){
	#if defined SSGI || defined SSR
		// Get model view normal
		vec3 gBMVNorm = mat3(gbufferModelView) * normal;
	#endif

	#ifdef SSGI
		// Get SSGI coord
		vec3 SSGIcoord = getSSGICoord(viewPos, screenPos, gBMVNorm, dither.xy);

		// If sky don't do SSGI
		#ifdef PREVIOUS_FRAME
			if(SSGIcoord.z > 0.5) sceneCol += albedo * texture2D(colortex5, toPrevScreenPos(SSGIcoord.xy)).rgb;
		#else
			if(SSGIcoord.z > 0.5) sceneCol += albedo * texture2D(gcolor, SSGIcoord.xy).rgb;
		#endif
	#endif

	// If smoothness is 0, don't do reflections
	if(smoothness > 0.005){
		bool isMetal = metallic > 0.9;

		// Get normalized eye player pos
		vec3 nEyePlayerPos = normalize(eyePlayerPos);
		// Get fresnel
		vec3 fresnel = getFresnelSchlick(max(dot(normal, -nEyePlayerPos), 0.0),
			isMetal ? albedo : vec3(metallic)) * smoothness;

		// Get SSR
		#ifdef SSR
			#ifdef ROUGH_REFLECTIONS
				// Rough the normals with noise
				gBMVNorm = normalize(gBMVNorm + (dither - 0.5) * squared(1.0 - smoothness) * 0.8);

				// Assign new rough normals
				normal = mat3(gbufferModelViewInverse) * gBMVNorm;
			#endif

			// Get SSR coord
			vec3 SSRCoord = getSSRCoord(viewPos, screenPos, gBMVNorm, dither.x);
			
			#ifdef PREVIOUS_FRAME
				// Get reflections and check for sky
				vec3 reflectCol = SSRCoord.z < 0.5 ? getSkyRender(vec3(0), skyCol, lightCol, reflect(nEyePlayerPos, normal), true, true) : texture2D(colortex5, toPrevScreenPos(SSRCoord.xy)).rgb;
			#else
				// Get reflections and check for sky
				vec3 reflectCol = SSRCoord.z < 0.5 ? getSkyRender(vec3(0), skyCol, lightCol, reflect(nEyePlayerPos, normal), true, true) : texture2D(gcolor, SSRCoord.xy).rgb;
			#endif
		#else
			vec3 reflectCol = getSkyRender(vec3(0), skyCol, lightCol, reflect(nEyePlayerPos, normal), true, true);
		#endif

		// Simplified and modified version of BSL's reflection PBR calculation
		sceneCol *= isMetal ? vec3(1.0 - smoothness) : 1.0 - fresnel;
		sceneCol += reflectCol * fresnel;
	}

	return sceneCol;
}