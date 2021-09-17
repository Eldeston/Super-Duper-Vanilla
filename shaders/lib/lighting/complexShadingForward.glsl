vec4 complexShadingGbuffers(matPBR material, positionVectors posVector, vec3 dither){
	#ifdef USE_SKY_LIGHTMAP
		material.light_m.y = (material.light_m.y * SKY_LIGHT_AMOUNT) / 0.95;
	#else
		material.light_m.y = SKY_LIGHT_AMOUNT;
	#endif

	// Get positions
	vec3 nLightPos = normalize(posVector.lightPos);
    vec3 nNegEyePlayerPos = normalize(-posVector.eyePlayerPos);

	vec3 totalDiffuse = vec3(0);
	vec3 dirLight = vec3(0);

	// Get globally illuminated sky
	vec3 GISky = ambientLighting + getLowSkyRender(material.normal_m, 0.0) * material.light_m.y * material.light_m.y;
	totalDiffuse = GISky * material.ambient_m;

	#ifdef ENABLE_LIGHT
		#if defined ENTITIES_GLOWING || !defined SHD_ENABLE
			// Get direct light diffuse color
			dirLight = getDiffuse(material.normal_m, nLightPos, material.ss_m) * smoothstep(0.98, 0.99, material.light_m.y) * material.light_m.y * lightCol;
		#else
			// Cave fix
			float caveFixShdFactor = smoothstep(0.2, 0.4, material.light_m.y) * (1.0 - eyeBrightFact) + eyeBrightFact;
			// Get direct light diffuse color
			dirLight = getShdMapping(posVector.shdPos, material.normal_m, nLightPos, dither.r, material.ss_m) * caveFixShdFactor * lightCol;
		#endif

		float rainDiff = isEyeInWater == 1 ? 0.2 : rainStrength * 0.5;
		totalDiffuse += dirLight * (1.0 - rainDiff) + material.light_m.y * material.ambient_m * lightCol * rainDiff;
	#endif
	
	vec3 specCol = vec3(0);

	#ifdef ENABLE_LIGHT
		if(maxC(dirLight) > 0){
			// Get fresnel
			vec3 fresnel = getFresnelSchlick(max(dot(material.normal_m, nNegEyePlayerPos), 0.0),
				material.metallic_m > 0.9 ? material.albedo_t.rgb : vec3(material.metallic_m));

			// Get specular GGX
			specCol = getSpecGGX(nNegEyePlayerPos, nLightPos, normalize(posVector.lightPos - posVector.eyePlayerPos), material.normal_m, fresnel, material.roughness_m) * dirLight;
		}
	#endif
 
	totalDiffuse = material.albedo_t.rgb * (totalDiffuse + cubed(material.light_m.x) * BLOCK_LIGHT_COL * pow(material.ambient_m, 1.0 / 4.0));
	return vec4(totalDiffuse + specCol + material.albedo_t.rgb * material.emissive_m, material.albedo_t.a);
}