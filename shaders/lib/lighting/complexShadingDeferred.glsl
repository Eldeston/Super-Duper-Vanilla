vec3 complexShadingDeferred(matPBR material, positionVectors posVector, vec3 sceneCol, vec3 dither){
	// Get positions
    vec3 nEyePlayerPos = normalize(-posVector.eyePlayerPos);

	vec3 gBMVNorm = mat3(gbufferModelView) * material.normal_m;

	#ifdef SSGI
		// Get SSGI
		vec3 GIcol = getSSGICol(posVector.viewPos, posVector.clipPos, gBMVNorm, toRandPerFrame(dither.xy));
	#else
		vec3 GIcol = vec3(0);
	#endif

	vec4 SSRCol = vec4(0);
	vec3 fresnel = vec3(0);

	// If roughness is 1, don't do reflections
	if(material.roughness_m != 1){
		// Get fresnel
		fresnel = getFresnelSchlick(dot(material.normal_m, nEyePlayerPos),
			mix(vec3(0.04), material.albedo_t.rgb, material.metallic_m));
		
		#ifdef SSR
			#ifdef ROUGH_REFLECTIONS
				SSRCol = getSSRCol(posVector.viewPos, posVector.clipPos,
					gBMVNorm + (dither * 2.0 - 1.0) * squared(material.roughness_m * material.roughness_m));
			#else
				SSRCol = getSSRCol(posVector.viewPos, posVector.clipPos, gBMVNorm);
			#endif
		#endif
	}

	float mask = material.metallic_m * SSRCol.a;
	return (sceneCol + material.albedo_t.rgb * GIcol) * (1.0 - mask) + SSRCol.rgb * fresnel * (1.0 - material.roughness_m) * SSRCol.a + material.albedo_t.rgb * material.emissive_m * mask;
}