#ifdef WORLD_LIGHT
	uniform float shdFade;
#endif

vec4 complexShadingGbuffers(matPBR material, vec3 eyePlayerPos, vec3 feetPlayerPos){
	// Get lightmaps and add simple sky GI
	vec3 totalDiffuse = (pow(SKY_COL_DATA_BLOCK * lmCoord.y, vec3(GAMMA)) +
		pow((lmCoord.x * BLOCKLIGHT_I * 0.00392156863) * vec3(BLOCKLIGHT_R, BLOCKLIGHT_G, BLOCKLIGHT_B), vec3(GAMMA)) +
		pow(AMBIENT_LIGHTING + nightVision * 0.5, GAMMA)) * material.ambient;

	#ifdef WORLD_LIGHT
		// Get sRGB light color
		vec3 sRGBLightCol = LIGHT_COL_DATA_BLOCK;

		float NL = max(0.0, dot(material.normal, vec3(shadowModelView[0].z, shadowModelView[1].z, shadowModelView[2].z)));
		// also equivalent to:
		// vec3(0, 0, 1) * mat3(shadowModelView) = vec3(shadowModelView[0].z, shadowModelView[1].z, shadowModelView[2].z)
    	// shadowLightPosition is broken in other dimensions. The current is equivalent to:
    	// normalize(mat3(gbufferModelViewInverse) * shadowLightPosition + gbufferModelViewInverse[3].xyz)

		#ifdef SUBSURFACE_SCATTERING
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
				float caveFixShdFactor = isEyeInWater == 1 ? 1.0 : min(1.0, lmCoord.y * 2.0) * (1.0 - eyeBrightFact) + eyeBrightFact;

				// Get shadow pos
				vec3 shdPos = mat3(shadowProjection) * (mat3(shadowModelView) * feetPlayerPos + shadowModelView[3].xyz) + shadowProjection[3].xyz;
				
				// Bias mutilplier, adjusts according to the current shadow distance and resolution
				float biasAdjustMult = exp2(max(0.0, (shadowDistance - shadowMapResolution * 0.125) / shadowDistance));
				float distortFactor = getDistortFactor(shdPos.xy);

				// Apply bias according to normal in shadow space
				shdPos += mat3(shadowProjection) * (mat3(shadowModelView) * material.normal) * biasAdjustMult * biasAdjustMult * distortFactor * 0.5;
				shdPos = distort(shdPos, distortFactor) * 0.5 + 0.5;

				// Sample shadows
				#ifdef SHD_FILTER
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
			// Sample fake shadows
			float shadowCol = smoothstep(0.94, 0.96, lmCoord.y) * shdFade * material.parallaxShd;
		#endif

		float rainDiff = rainStrength * 0.5;
		totalDiffuse += (dirLight * shadowCol * (1.0 - rainDiff) + lmCoord.y * lmCoord.y * material.ambient * rainDiff) * pow(sRGBLightCol, vec3(GAMMA));
	#endif

	totalDiffuse = material.albedo.rgb * (totalDiffuse + material.emissive * EMISSIVE_INTENSITY);

	#ifdef WORLD_LIGHT
		if(NL > 0){
			// Get specular GGX
			vec3 specCol = getSpecBRDF(normalize(-eyePlayerPos), vec3(shadowModelView[0].z, shadowModelView[1].z, shadowModelView[2].z), material.normal, material.metallic > 0.9 ? material.albedo.rgb : vec3(material.metallic), NL, 1.0 - material.smoothness);
			// Needs to multiplied twice in order for the speculars to look relatively "correct"
			totalDiffuse += min(vec3(SUN_MOON_INTENSITY * SUN_MOON_INTENSITY), specCol) * sRGBLightCol * (1.0 - rainStrength) * shadowCol * 2.0;
		}
	#endif

	return vec4(totalDiffuse, material.albedo.a);
}