vec3 complexShadingDeferred(matPBR material, positionVectors posVector, vec3 sceneCol, vec3 dither){
	#if defined SSGI || defined SSR
		// Get positions
		vec3 gBMVNorm = mat3(gbufferModelView) * material.normal_m;
	#endif
	
	bool isMetal = material.metallic_m > 0.9;

	#ifdef SSGI
		// Get SSGI
		vec3 GIcol = vec3(0);
		if(!isMetal) GIcol = getSSGICol(posVector.viewPos, posVector.clipPos, gBMVNorm, toRandPerFrame(dither.xy));
		sceneCol += material.albedo_t.rgb * GIcol;
	#endif

	// Get fresnel
	vec3 fresnel = getFresnelSchlick(max(dot(material.normal_m, normalize(-posVector.eyePlayerPos)), 0.0),
		isMetal ? material.albedo_t.rgb : vec3(material.metallic_m));
	
	// If roughness is 1, don't do reflections
	vec3 reflectCol = vec3(0);

	if(material.roughness_m < 1.0){
		#ifdef SSR
			#ifdef ROUGH_REFLECTIONS
				vec4 SSRCol = getSSRCol(posVector.viewPos, posVector.clipPos,
					gBMVNorm + (dither * 2.0 - 1.0) * material.roughness_m * material.roughness_m);
			#else
				vec4 SSRCol = getSSRCol(posVector.viewPos, posVector.clipPos, gBMVNorm);
			#endif

			reflectCol = ambientLighting + getLowSkyRender(reflect(posVector.eyePlayerPos, material.normal_m), 1.0) * eyeBrightFact;
			reflectCol = mix(reflectCol, SSRCol.rgb, SSRCol.a);
		#else
			reflectCol = ambientLighting + getLowSkyRender(reflect(posVector.eyePlayerPos, material.normal_m), 1.0) * eyeBrightFact;
		#endif
	}

	return mix(sceneCol * (isMetal ? material.roughness_m : 1.0), reflectCol, fresnel * squared(1.0 - material.roughness_m) * (1.0 - material.emissive_m));
}