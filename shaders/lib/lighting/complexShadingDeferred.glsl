vec3 complexShadingDeferred(matPBR material, positionVectors posVector, vec3 sceneCol, vec3 dither){
	#if defined SSGI || defined SSR
		// Get positions
		vec3 gBMVNorm = mat3(gbufferModelView) * material.normal;
	#endif
	
	bool isMetal = material.metallic > 0.9;

	#ifdef SSGI
		// Get SSGI
		vec3 GIcol = vec3(0);
		if(!isMetal) GIcol = getSSGICol(posVector.viewPos, posVector.clipPos, gBMVNorm, toRandPerFrame(dither.xy));
		sceneCol += material.albedo.rgb * GIcol;
	#endif

	// Get fresnel
	vec3 fresnel = getFresnelSchlick(max(dot(material.normal, normalize(-posVector.eyePlayerPos)), 0.0),
		isMetal ? material.albedo.rgb : vec3(material.metallic));
	
	// If smoothness is 0, don't do reflections
	vec3 reflectCol = vec3(0);

	if(material.smoothness > 0.0){
		#ifdef SSR
			#ifdef ROUGH_REFLECTIONS
				vec4 SSRCol = getSSRCol(posVector.viewPos, posVector.clipPos,
					gBMVNorm + (dither * 2.0 - 1.0) * squared(squared(1.0 - material.smoothness)));
			#else
				vec4 SSRCol = getSSRCol(posVector.viewPos, posVector.clipPos, gBMVNorm);
			#endif

			reflectCol = ambientLighting + getLowSkyRender(reflect(posVector.eyePlayerPos, material.normal), 1.0) * eyeBrightFact;
			reflectCol = mix(reflectCol, SSRCol.rgb, SSRCol.a);
		#else
			reflectCol = ambientLighting + getLowSkyRender(reflect(posVector.eyePlayerPos, material.normal), 1.0) * eyeBrightFact;
		#endif
	}

	// Simplified and modified version of BSL's reflection PBR calculation
	sceneCol *= 1.0 - (isMetal ? vec3(material.smoothness) : fresnel * material.smoothness) * (1.0 - material.emissive);
	return sceneCol + reflectCol * fresnel * material.smoothness;
}