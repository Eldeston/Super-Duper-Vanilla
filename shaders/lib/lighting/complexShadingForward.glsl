vec4 complexShadingGbuffers(matPBR material, positionVectors posVector, float dither){
	#ifdef USE_SKY_LIGHTMAP
		material.light.y *= SKY_LIGHT_AMOUNT;
	#else
		material.light.y = SKY_LIGHT_AMOUNT;
	#endif

	vec3 specCol = vec3(0);

	// Get lightmaps and add simple sky GI
	vec3 totalDiffuse = (skyCol * material.light.y * material.light.y + ambientLighting + material.light.x * material.light.x * pow((BLOCKLIGHT_I * 0.00392156863) * vec3(BLOCKLIGHT_R, BLOCKLIGHT_G, BLOCKLIGHT_B), vec3(GAMMA))) * material.ambient;

	#ifdef ENABLE_LIGHT
		// Get positions
		vec3 nLightPos = normalize(posVector.lightPos);
		vec3 nNegEyePlayerPos = normalize(-posVector.eyePlayerPos);
		float NL = saturate(dot(material.normal, nLightPos));

		#ifdef ENABLE_SS
			// Diffuse with simple SS approximation
			float dirLight = NL * (1.0 - material.ss) + material.ss;
		#else
			#define dirLight NL
		#endif

		#if defined SHD_ENABLE && !defined ENTITIES_GLOWING
			// Cave fix
			float caveFixShdFactor = smoothstep(0.2, 0.4, material.light.y) * (1.0 - eyeBrightFact) + eyeBrightFact;
			vec3 shdCol = getShdMapping(posVector.shdPos, dirLight, dither) * (isEyeInWater == 1 ? 1.0 : caveFixShdFactor);
		#else
			vec3 shdCol = vec3(smoothstep(0.94, 0.96, material.light.y));
		#endif

		float rainDiff = rainStrength * 0.5;
		totalDiffuse += (dirLight * shdCol * (1.0 - rainDiff) + material.light.y * material.light.y * material.ambient * rainDiff) * lightCol;

		// Get specular GGX
		if(NL > 0) specCol = getSpecBRDF(nNegEyePlayerPos, nLightPos, material.normal, material.metallic > 0.9 ? material.albedo.rgb : vec3(material.metallic), NL, 1.0 - material.smoothness) * NL * shdCol;
	#endif

	totalDiffuse = material.albedo.rgb * (totalDiffuse + material.emissive * 4.0);
	return vec4(totalDiffuse + specCol, material.albedo.a);
}