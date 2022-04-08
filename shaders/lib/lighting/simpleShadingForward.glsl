#ifdef WORLD_LIGHT
	uniform float shdFade;
#endif

vec4 simpleShadingGbuffers(vec4 albedo, vec3 feetPlayerPos, vec3 normal, vec2 light, float ss, float dither){
	#ifdef WORLD_SKYLIGHT_AMOUNT
		light.y = WORLD_SKYLIGHT_AMOUNT;
	#endif

	// Get lightmaps and add simple sky GI
	vec3 totalDiffuse = skyCol * light.y * light.y + ambientLighting + pow((light.x * BLOCKLIGHT_I * 0.00392156863) * vec3(BLOCKLIGHT_R, BLOCKLIGHT_G, BLOCKLIGHT_B), vec3(GAMMA));

	#ifdef WORLD_LIGHT
		float NL = max(0.0, dot(normal, vec3(shadowModelView[0].z, shadowModelView[1].z, shadowModelView[2].z)));
		// also equivalent to:
		// vec3(0, 0, 1) * mat3(shadowModelView) = vec3(shadowModelView[0].z, shadowModelView[1].z, shadowModelView[2].z)
    	// shadowLightPosition is broken in other dimensions. The current is equivalent to:
    	// normalize(mat3(gbufferModelViewInverse) * shadowLightPosition + gbufferModelViewInverse[3].xyz)

		#ifdef ENABLE_SS
			// Diffuse with simple SS approximation
			float dirLight = NL * (1.0 - ss) + ss;
		#else
			#define dirLight NL
		#endif

		#ifdef SHD_ENABLE
			// Cave fix
			float caveFixShdFactor = isEyeInWater == 1 ? 1.0 : smoothstep(0.4, 0.8, light.y) * (1.0 - eyeBrightFact) + eyeBrightFact;
			vec3 shadow = getShdMapping(mat3(shadowProjection) * (mat3(shadowModelView) * feetPlayerPos + shadowModelView[3].xyz) + shadowProjection[3].xyz, dirLight, dither) * caveFixShdFactor * shdFade;
		#else
			float shadow = smoothstep(0.94, 0.96, light.y) * shdFade;
		#endif

		float rainDiff = rainStrength * 0.5;
		totalDiffuse += (dirLight * shadow * (1.0 - rainDiff) + light.y * light.y * rainDiff) * lightCol;
	#endif

	return vec4(albedo.rgb * totalDiffuse, albedo.a);
}