vec3 complexShadingDeferred(matPBR material, positionVectors posVector, vec3 sceneCol, vec3 dither){
	// Get positions
    vec3 nEyePlayerPos = normalize(-posVector.eyePlayerPos);

	vec3 gBMVNorm = mat3(gbufferModelView) * material.normal_m;

	#ifdef SSGI
		// Get SSGI
		vec3 GIcol = getSSGICol(posVector.viewPos, posVector.screenPos, gBMVNorm, dither.xy);
	#else
		vec3 GIcol = vec3(0);
	#endif

	// Get fresnel
    vec3 F0 = mix(vec3(0.04), material.albedo_t.rgb, material.metallic_m);
    vec3 fresnel = getFresnelSchlick(dot(material.normal_m, nEyePlayerPos), F0);

	#ifdef SSR
		#ifdef ROUGH_REFLECTIONS
			vec4 SSRCol = getSSRCol(posVector.viewPos, posVector.screenPos, gBMVNorm + (dither * 2.0 - 1.0) * squared(material.roughness_m * material.roughness_m));
		#else
			vec4 SSRCol = getSSRCol(posVector.viewPos, posVector.screenPos, gBMVNorm);
		#endif
	#else
		vec4 SSRCol = vec4(0);
	#endif

	float mask = material.metallic_m * SSRCol.a;
	return (sceneCol + material.albedo_t.rgb * GIcol) * (1.0 - mask) + SSRCol.rgb * fresnel * (1.0 - material.roughness_m) * SSRCol.a + material.albedo_t.rgb * material.emissive_m * mask;
}