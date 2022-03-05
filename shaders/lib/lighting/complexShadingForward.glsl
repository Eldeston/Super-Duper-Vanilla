#ifdef WORLD_LIGHT
	uniform float shdFade;
#endif

vec4 complexShadingGbuffers(matPBR material, positionVectors posVector, float dither){
	#ifdef WORLD_SKYLIGHT_AMOUNT
		material.light.y = WORLD_SKYLIGHT_AMOUNT;
	#endif

	// Get lightmaps and add simple sky GI
	vec3 totalDiffuse = (skyCol * material.light.y * material.light.y + ambientLighting + material.light.x * material.light.x * pow((BLOCKLIGHT_I * 0.00392156863) * vec3(BLOCKLIGHT_R, BLOCKLIGHT_G, BLOCKLIGHT_B), vec3(GAMMA))) * material.ambient;

	#ifdef WORLD_LIGHT
		float NL = saturate(dot(material.normal, vec3(shadowModelView[0].z, shadowModelView[1].z, shadowModelView[2].z)));
		// also equivalent to:
		// vec3(0, 0, 1) * mat3(shadowModelView) = vec3(shadowModelView[0].z, shadowModelView[1].z, shadowModelView[2].z)
    	// shadowLightPosition is broken in other dimensions. The current is equivalent to:
    	// normalize(mat3(gbufferModelViewInverse) * shadowLightPosition + gbufferModelViewInverse[3].xyz)

		#ifdef ENABLE_SS
			// Diffuse with simple SS approximation
			float dirLight = NL * (1.0 - material.ss) + material.ss;
		#else
			#define dirLight NL
		#endif

		#if defined SHD_ENABLE && !defined ENTITIES_GLOWING
			// Cave fix
			float caveFixShdFactor = smoothstep(0.4, 0.8, material.light.y) * (1.0 - eyeBrightFact) + eyeBrightFact;
			vec3 shadow = getShdMapping(mat3(shadowProjection) * (mat3(shadowModelView) * posVector.feetPlayerPos + shadowModelView[3].xyz) + shadowProjection[3].xyz, dirLight, dither) * (isEyeInWater == 1 ? 1.0 : caveFixShdFactor) * shdFade * material.parallaxShd;
		#else
			float shadow = smoothstep(0.94, 0.96, material.light.y) * shdFade * material.parallaxShd;
		#endif

		float rainDiff = rainStrength * 0.5;
		totalDiffuse += (dirLight * shadow * (1.0 - rainDiff) + material.light.y * material.light.y * material.ambient * rainDiff) * lightCol;
	#endif

	totalDiffuse = material.albedo.rgb * (totalDiffuse + material.emissive * EMISSIVE_INTENSITY);

	#ifdef WORLD_LIGHT
		if(NL > 0){
			// Get specular GGX
			vec3 specCol = getSpecBRDF(normalize(-posVector.eyePlayerPos), vec3(shadowModelView[0].z, shadowModelView[1].z, shadowModelView[2].z), material.normal, material.metallic > 0.9 ? material.albedo.rgb : vec3(material.metallic), NL, 1.0 - material.smoothness) * shadow * NL;
			totalDiffuse += min(vec3(SUN_MOON_INTENSITY * SUN_MOON_INTENSITY), specCol) * sqrt(lightCol);
		}
	#endif

	return vec4(totalDiffuse, material.albedo.a);
}