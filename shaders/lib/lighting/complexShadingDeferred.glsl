vec3 complexShadingDeferred(matPBR material, positionVectors posVector, vec3 sceneCol, vec3 dither){
	// Get positions
	vec3 gBMVNorm = mat3(gbufferModelView) * material.normal_m;
	
	float roughnessSqrt = sqrt(material.roughness_m);
	bool isMetal = material.metallic_m > 0.9;

	#ifdef SSGI
		// Get SSGI
		vec3 GIcol = vec3(0);
		if(!isMetal) GIcol = getSSGICol(posVector.viewPos, posVector.clipPos, gBMVNorm, toRandPerFrame(dither.xy));
		sceneCol += material.albedo_t.rgb * GIcol * (isMetal ? roughnessSqrt : 1.0);
	#endif

	#ifdef SSR
		// Get fresnel
		vec3 fresnel = getFresnelSchlick(max(dot(material.normal_m, normalize(-posVector.eyePlayerPos)), 0.0),
			isMetal ? material.albedo_t.rgb : vec3(material.metallic_m));

		// If roughness is 1, don't do reflections
		vec4 SSRCol = vec4(0);
		#ifdef ROUGH_REFLECTIONS
			if(material.roughness_m != 1) SSRCol = getSSRCol(posVector.viewPos, posVector.clipPos,
				gBMVNorm + (dither * 2.0 - 1.0) * material.roughness_m * material.roughness_m);
		#else
			if(material.roughness_m != 1) SSRCol = getSSRCol(posVector.viewPos, posVector.clipPos, gBMVNorm);
		#endif

		vec3 mask = fresnel * SSRCol.a * (1.0 - roughnessSqrt);
		sceneCol = mix(sceneCol, SSRCol.rgb, mask * (1.0 - material.emissive_m));
	#endif

	return sceneCol;
}