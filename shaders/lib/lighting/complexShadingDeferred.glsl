vec3 complexShadingDeferred(vec3 screenPos, vec3 viewPos, vec3 eyePlayerPos, vec3 normal, vec3 albedo, vec3 sceneCol, float metallic, float smoothness, vec3 dither){
	#if defined SSGI || defined SSR
		// Get model view normal
		vec3 gBMVNorm = mat3(gbufferModelView) * normal;
	#endif

	#ifdef SSGI
		// Get SSGI
		sceneCol += albedo * getSSGICol(viewPos, screenPos, gBMVNorm, dither.xy);
	#endif

	// If smoothness is 0, don't do reflections
	if(smoothness > 0.005){
		bool isMetal = metallic > 0.9;

		// Get fresnel
		vec3 fresnel = getFresnelSchlick(max(dot(normal, normalize(-eyePlayerPos)), 0.0),
			isMetal ? albedo : vec3(metallic)) * smoothness;

		// Get SSR
		#ifdef SSR
			#ifdef ROUGH_REFLECTIONS
				// Rough the normals with noise
				gBMVNorm = normalize(gBMVNorm + (dither - 0.5) * squared(1.0 - smoothness) * 0.8);

				// Assign new rough normals
				normal = mat3(gbufferModelViewInverse) * gBMVNorm;
			#endif

			// Get SSR
			vec4 SSRCol = getSSRCol(viewPos, screenPos, gBMVNorm, dither.x);

			vec3 reflectCol = getSkyRender(vec3(0), normalize(reflect(eyePlayerPos, normal)), SSRCol.a != 0);
			reflectCol = mix(reflectCol, SSRCol.rgb, SSRCol.a);
		#else
			vec3 reflectCol = getSkyRender(vec3(0), normalize(reflect(eyePlayerPos, normal)), true);
		#endif

		// Simplified and modified version of BSL's reflection PBR calculation
		sceneCol *= 1.0 - (isMetal ? vec3(smoothness) : fresnel);
		sceneCol += reflectCol * fresnel;
	}

	return sceneCol;
}