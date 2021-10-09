vec4 complexShadingGbuffers(matPBR material, positionVectors posVector, vec3 dither){
	#ifdef USE_SKY_LIGHTMAP
		material.light.y = material.light.y * SKY_LIGHT_AMOUNT;
	#else
		material.light.y = SKY_LIGHT_AMOUNT;
	#endif

	// Get positions
	vec3 nLightPos = normalize(posVector.lightPos);

	vec3 specCol = vec3(0);

	// Get sky global illumination
	vec3 skyGI = ambientLighting + getSkyRender(material.normal, false) * material.light.y * material.light.y;
	// Get lightmaps and add sky GI
	vec3 totalDiffuse = (skyGI + cubed(material.light.x) * BLOCK_LIGHT_COL) * smootherstep(material.ambient);

	#ifdef ENABLE_LIGHT
		float NL = saturate(dot(material.normal, nLightPos));
		float dirLight = getDiffuse(NL, material.ss);

		#if defined ENTITIES_GLOWING || !defined SHD_ENABLE
			// Get direct light diffuse color
			vec3 shdCol = vec3(smoothstep(0.94, 0.96, material.light.y));
		#else
			// Cave fix
			float caveFixShdFactor = smoothstep(0.2, 0.4, material.light.y) * (1.0 - eyeBrightFact) + eyeBrightFact;
			// Get direct light diffuse color
			vec3 shdCol = getShdMapping(posVector.shdPos, dirLight, dither.r) * caveFixShdFactor;
		#endif

		float rainDiff = isEyeInWater == 1 ? 0.2 : rainStrength * 0.5;
		totalDiffuse += (dirLight * shdCol * (1.0 - rainDiff) + material.light.y * material.ambient * rainDiff) * lightCol;

		// Get specular GGX
		if(dirLight > 0) specCol = getSpecBRDF(normalize(-posVector.eyePlayerPos), nLightPos, material.normal, material.metallic > 0.9 ? material.albedo.rgb : vec3(material.metallic), NL, 1.0 - material.smoothness) * NL * shdCol;
	#endif

	totalDiffuse = material.albedo.rgb * (totalDiffuse + material.emissive);
	return vec4(totalDiffuse + specCol, material.albedo.a);
}