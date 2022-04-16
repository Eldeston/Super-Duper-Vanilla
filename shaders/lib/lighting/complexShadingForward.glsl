#ifdef WORLD_LIGHT
	uniform float shdFade;
#endif

vec4 complexShadingGbuffers(matPBR material, positionVectors posVector){
	// Get lightmaps and add simple sky GI
	vec3 totalDiffuse = (skyCol * lmCoord.y * lmCoord.y + ambientLighting + pow((lmCoord.x * BLOCKLIGHT_I * 0.00392156863) * vec3(BLOCKLIGHT_R, BLOCKLIGHT_G, BLOCKLIGHT_B), vec3(GAMMA))) * material.ambient;

	#ifdef WORLD_LIGHT
		float NL = max(0.0, dot(material.normal, vec3(shadowModelView[0].z, shadowModelView[1].z, shadowModelView[2].z)));
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
			vec3 shadowCol = vec3(0);

			// If the area isn't shaded, apply shadow mapping
			if(dirLight > 0){
				// Cave light leak fix
				float caveFixShdFactor = isEyeInWater == 1 ? 1.0 : smoothstep(0.4, 0.8, lmCoord.y) * (1.0 - eyeBrightFact) + eyeBrightFact;

				vec3 shdPos = mat3(shadowProjection) * (mat3(shadowModelView) * posVector.feetPlayerPos + shadowModelView[3].xyz) + shadowProjection[3].xyz;
				float distortFactor = getDistortFactor(shdPos.xy);
				shdPos += mat3(shadowProjection) * (mat3(shadowModelView) * material.normal) * squared(exp2(max(0.0, (shadowDistance - shadowMapResolution * 0.125) / shadowDistance))) * distortFactor * 0.5;
				shdPos = distort(shdPos, distortFactor) * 0.5 + 0.5;

				#ifdef SHADOW_FILTER
					#if ANTI_ALIASING == 2
						shadowCol = getShdFilter(shdPos, toRandPerFrame(texture2D(noisetex, gl_FragCoord.xy * 0.03125).x, frameTimeCounter) * PI2) * caveFixShdFactor * shdFade * material.parallaxShd;
					#else
						shadowCol = getShdFilter(shdPos, texture2D(noisetex, gl_FragCoord.xy * 0.03125).x * PI2) * caveFixShdFactor * shdFade * material.parallaxShd;
					#endif
				#else
					shadowCol = getShdTex(shdPos) * caveFixShdFactor * shdFade * material.parallaxShd;
				#endif
			}
		#else
			float shadowCol = smoothstep(0.94, 0.96, lmCoord.y) * shdFade * material.parallaxShd;
		#endif

		float rainDiff = rainStrength * 0.5;
		totalDiffuse += (dirLight * shadowCol * (1.0 - rainDiff) + lmCoord.y * lmCoord.y * material.ambient * rainDiff) * lightCol;
	#endif

	totalDiffuse = material.albedo.rgb * (totalDiffuse + material.emissive * EMISSIVE_INTENSITY);

	#ifdef WORLD_LIGHT
		if(NL > 0){
			// Get specular GGX
			vec3 specCol = getSpecBRDF(normalize(-posVector.eyePlayerPos), vec3(shadowModelView[0].z, shadowModelView[1].z, shadowModelView[2].z), material.normal, material.metallic > 0.9 ? material.albedo.rgb : vec3(material.metallic), NL, 1.0 - material.smoothness);
			totalDiffuse += min(vec3(SUN_MOON_INTENSITY * SUN_MOON_INTENSITY), specCol) * sqrt(lightCol) * (1.0 - rainStrength) * shadowCol;
		}
	#endif

	return vec4(totalDiffuse, material.albedo.a);
}