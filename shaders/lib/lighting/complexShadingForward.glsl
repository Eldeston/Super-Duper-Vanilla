vec4 complexShadingGbuffers(matPBR material, positionVectors posVector, vec3 dither){
	#ifdef USE_SKY_LIGHTMAP
		material.light.y = (material.light.y * SKY_LIGHT_AMOUNT) / 0.95;
	#else
		material.light.y = SKY_LIGHT_AMOUNT;
	#endif

	// Get positions
	vec3 nLightPos = normalize(posVector.lightPos);
    vec3 nNegEyePlayerPos = normalize(-posVector.eyePlayerPos);

	vec3 totalDiffuse = vec3(0);
	vec3 dirLight = vec3(0);

	// Get globally illuminated sky
	vec3 GISky = ambientLighting + getLowSkyRender(material.normal, 0.0) * material.light.y * material.light.y;
	totalDiffuse = GISky * material.ambient;

	#ifdef ENABLE_LIGHT
		#if defined ENTITIES_GLOWING || !defined SHD_ENABLE
			// Get direct light diffuse color
			dirLight = getDiffuse(material.normal, nLightPos, material.ss) * smoothstep(0.98, 0.99, material.light.y) * material.light.y * lightCol;
		#else
			// Cave fix
			float caveFixShdFactor = smoothstep(0.2, 0.4, material.light.y) * (1.0 - eyeBrightFact) + eyeBrightFact;
			// Get direct light diffuse color
			dirLight = getShdMapping(posVector.shdPos, material.normal, nLightPos, dither.r, material.ss) * caveFixShdFactor * lightCol;
		#endif

		float rainDiff = isEyeInWater == 1 ? 0.2 : rainStrength * 0.5;
		totalDiffuse += dirLight * (1.0 - rainDiff) + material.light.y * material.ambient * lightCol * rainDiff;
	#endif
	
	vec3 specCol = vec3(0);

	#ifdef ENABLE_LIGHT
		// Get specular GGX
		if(maxC(dirLight) > 0) specCol = getSpecBRDF(nNegEyePlayerPos, nLightPos, material.normal, material.metallic > 0.9 ? material.albedo.rgb : vec3(material.metallic), 1.0 - material.smoothness) * dirLight;
	#endif
 
	totalDiffuse = material.albedo.rgb * (totalDiffuse + cubed(material.light.x) * BLOCK_LIGHT_COL * pow(material.ambient, 1.0 / 4.0));
	return vec4(totalDiffuse + specCol + material.albedo.rgb * material.emissive, material.albedo.a);
}