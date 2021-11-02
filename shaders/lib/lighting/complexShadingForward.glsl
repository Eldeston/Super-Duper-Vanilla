vec4 complexShadingGbuffers(matPBR material, positionVectors posVector, vec3 dither){
	#ifdef USE_SKY_LIGHTMAP
		material.light.y *= SKY_LIGHT_AMOUNT;
	#else
		material.light.y = SKY_LIGHT_AMOUNT;
	#endif

	vec3 specCol = vec3(0);

	// Get sky global illumination
	vec3 skyGI = getSkyRender(material.normal, false) * material.light.y * material.light.y;
	// Get lightmaps and add sky GI
	vec3 totalDiffuse = (skyGI + ambientLighting + cubed(material.light.x) * BLOCK_LIGHT_COL) * smoothen(material.ambient);

	#ifdef ENABLE_LIGHT
		// Get positions
		vec3 nLightPos = normalize(posVector.lightPos);
		vec3 nNegEyePlayerPos = normalize(-posVector.eyePlayerPos);
		float NL = saturate(dot(material.normal, nLightPos));
		
		// Diffuse with simple SS approximation
		float dirLight = mix(material.ss * (dot(nNegEyePlayerPos, -nLightPos) * 0.5 + 0.5), 1.0, NL) * (1.0 - newTwilight);

		#if defined SHD_ENABLE && !defined ENTITIES_GLOWING
			// Cave fix
			float caveFixShdFactor = smoothstep(0.2, 0.4, material.light.y) * (1.0 - eyeBrightFact) + eyeBrightFact;
			vec3 shdCol = getShdMapping(posVector.shdPos, dirLight, dither.r) * caveFixShdFactor;
		#else
			vec3 shdCol = vec3(smoothstep(0.94, 0.96, material.light.y));
		#endif

		float rainDiff = isEyeInWater == 1 ? 0.2 : rainStrength * 0.5;
		totalDiffuse += (dirLight * shdCol * (1.0 - rainDiff) + material.light.y * material.ambient * rainDiff) * lightCol;

		// Get specular GGX
		if(NL > 0) specCol = getSpecBRDF(nNegEyePlayerPos, nLightPos, material.normal, material.metallic > 0.9 ? material.albedo.rgb : vec3(material.metallic), NL, 1.0 - material.smoothness) * NL * shdCol;
	#endif

	totalDiffuse = material.albedo.rgb * (totalDiffuse + material.emissive);
	return vec4(totalDiffuse + specCol, material.albedo.a);
}