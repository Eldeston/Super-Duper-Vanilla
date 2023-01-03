#ifdef WORLD_LIGHT
	uniform float shdFade;
#endif

vec4 complexShadingGbuffers(in structPBR material){
	#ifdef DIRECTIONAL_LIGHTMAPS
		vec3 dirLightMapCoord = dFdx(vertexPos.xyz) * dFdx(lmCoord.x) + dFdy(vertexPos.xyz) * dFdy(lmCoord.x);
		float dirLightMap = min(1.0, max(0.0, dot(fastNormalize(dirLightMapCoord), material.normal)) * lmCoord.x * DIRECTIONAL_LIGHTMAP_STRENGTH + lmCoord.x);

		// Get lightmaps and add simple sky GI
		vec3 totalDiffuse = (toLinear(SKY_COL_DATA_BLOCK * lmCoord.y) +
			toLinear((dirLightMap * BLOCKLIGHT_I * 0.00392156863) * vec3(BLOCKLIGHT_R, BLOCKLIGHT_G, BLOCKLIGHT_B)) +
			toLinear(AMBIENT_LIGHTING + nightVision * 0.5)) * material.ambient;
	#else
		// Get lightmaps and add simple sky GI
		vec3 totalDiffuse = (toLinear(SKY_COL_DATA_BLOCK * lmCoord.y) +
			toLinear((lmCoord.x * BLOCKLIGHT_I * 0.00392156863) * vec3(BLOCKLIGHT_R, BLOCKLIGHT_G, BLOCKLIGHT_B)) +
			toLinear(AMBIENT_LIGHTING + nightVision * 0.5)) * material.ambient;
	#endif

	#ifdef WORLD_LIGHT
		// Get sRGB light color
		vec3 sRGBLightCol = LIGHT_COL_DATA_BLOCK;

		float NL = max(0.0, dot(material.normal, vec3(shadowModelView[0].z, shadowModelView[1].z, shadowModelView[2].z)));
		// also equivalent to:
		// vec3(0, 0, 1) * mat3(shadowModelView) = vec3(shadowModelView[0].z, shadowModelView[1].z, shadowModelView[2].z)
    	// shadowLightPosition is broken in other dimensions. The current is equivalent to:
    	// fastNormalize(mat3(gbufferModelViewInverse) * shadowLightPosition + gbufferModelViewInverse[3].xyz)

		#ifdef SUBSURFACE_SCATTERING
			// Diffuse with simple SS approximation
			float dirLight = NL + (1.0 - NL) * material.ambient * material.ss * 0.5;
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
				vec3 shdPos = vec3(shadowProjection[0].x, shadowProjection[1].y, shadowProjection[2].z) * (mat3(shadowModelView) * vertexPos.xyz + shadowModelView[3].xyz) + shadowProjection[3].xyz;
				
				// Bias mutilplier, adjusts according to the current shadow distance and resolution
				const float biasAdjustMult = log2(max(4.0, shadowDistance - shadowMapResolution * 0.125)) * 0.25;
				float distortFactor = getDistortFactor(shdPos.xy);

				// Apply bias according to normal in shadow space before
				shdPos += vec3(shadowProjection[0].x, shadowProjection[1].y, shadowProjection[2].z) * (mat3(shadowModelView) * material.normal) * distortFactor * biasAdjustMult;
				shdPos = distort(shdPos, distortFactor) * 0.5 + 0.5;

				// Sample shadows
				#ifdef SHD_FILTER
					#if ANTI_ALIASING >= 2
						shadowCol = getShdFilter(shdPos, toRandPerFrame(texelFetch(noisetex, ivec2(gl_FragCoord.xy) & 255, 0).x, frameTimeCounter) * TAU) * caveFixShdFactor * shdFade * material.parallaxShd;
					#else
						shadowCol = getShdFilter(shdPos, texelFetch(noisetex, ivec2(gl_FragCoord.xy) & 255, 0).x * TAU) * caveFixShdFactor * shdFade * material.parallaxShd;
					#endif
				#else
					shadowCol = getShdTex(shdPos) * caveFixShdFactor * shdFade * material.parallaxShd;
				#endif
			}
		#else
			// Sample fake shadows
			float shadowCol = saturate(hermiteMix(0.96, 0.98, lmCoord.y)) * shdFade * material.parallaxShd;
		#endif

		float rainDiff = rainStrength * 0.5;
		totalDiffuse += (dirLight * shadowCol * (1.0 - rainDiff) + lmCoord.y * lmCoord.y * material.ambient * rainDiff) * toLinear(sRGBLightCol);
	#endif

	totalDiffuse = material.albedo.rgb * (totalDiffuse + material.emissive * EMISSIVE_INTENSITY);

	#ifdef WORLD_LIGHT
		if(NL > 0){
			// Get specular GGX
			vec3 specCol = getSpecBRDF(fastNormalize(-vertexPos.xyz), vec3(shadowModelView[0].z, shadowModelView[1].z, shadowModelView[2].z), material.normal, material.albedo.rgb, NL, material.metallic, 1.0 - material.smoothness);
			// Needs to multiplied twice in order for the speculars to look relatively "correct"
			totalDiffuse += min(vec3(SUN_MOON_INTENSITY * SUN_MOON_INTENSITY), specCol) * sRGBLightCol * (1.0 - rainStrength) * shadowCol * 2.0;
		}
	#endif

	return vec4(totalDiffuse, material.albedo.a);
}