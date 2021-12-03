vec3 complexShadingDeferred(matPBR material, positionVectors posVector, vec3 sceneCol, vec3 dither){
	#if defined SSGI || defined SSR
		// Get positions
		vec3 gBMVNorm = mat3(gbufferModelView) * material.normal;
	#endif

	#ifdef SSGI
		// Get SSGI
		sceneCol += material.albedo.rgb * getSSGICol(posVector.viewPos, posVector.clipPos, gBMVNorm, toRandPerFrame(dither.xy, frameTimeCounter));
	#endif
	
	// If smoothness is 0, don't do reflections
	if(material.smoothness > 0.0){
		bool isMetal = material.metallic > 0.9;

		// Get fresnel
		vec3 fresnel = getFresnelSchlick(max(dot(material.normal, normalize(-posVector.eyePlayerPos)), 0.0),
			isMetal ? material.albedo.rgb : vec3(material.metallic)) * material.smoothness;

		// Get SSR
		#ifdef SSR
			#ifdef ROUGH_REFLECTIONS
				vec4 SSRCol = getSSRCol(posVector.viewPos, posVector.clipPos,
					normalize(gBMVNorm + (dither * 0.5 - 0.25) * squared(1.0 - material.smoothness)));
			#else
				vec4 SSRCol = getSSRCol(posVector.viewPos, posVector.clipPos, gBMVNorm);
			#endif

			vec3 reflectCol = ambientLighting + getSkyRender(reflect(posVector.eyePlayerPos, material.normal), true) * eyeBrightFact;
			reflectCol = mix(reflectCol, SSRCol.rgb, SSRCol.a);
		#else
			vec3 reflectCol = ambientLighting + getSkyRender(reflect(posVector.eyePlayerPos, material.normal), true) * eyeBrightFact;
		#endif

		// Simplified and modified version of BSL's reflection PBR calculation
		sceneCol *= 1.0 - (isMetal ? vec3(material.smoothness) : fresnel) * (1.0 - material.emissive);
		sceneCol += reflectCol * fresnel;
	}

	return sceneCol;
}