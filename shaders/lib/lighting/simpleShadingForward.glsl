#ifdef WORLD_LIGHT
	uniform float shdFade;
#endif

#ifdef CLOUDS
	vec4 simpleShadingGbuffers(vec4 albedo){
		// Get lightmaps and add simple sky GI
		vec3 totalDiffuse = pow(SKY_COL_DATA_BLOCK, vec3(GAMMA)) +
			pow(AMBIENT_LIGHTING + nightVision * 0.5, GAMMA);

		#ifdef WORLD_LIGHT
			float NL = max(0.0, dot(norm, vec3(shadowModelView[0].z, shadowModelView[1].z, shadowModelView[2].z))) * 0.6 + 0.4;
			// also equivalent to:
			// vec3(0, 0, 1) * mat3(shadowModelView) = vec3(shadowModelView[0].z, shadowModelView[1].z, shadowModelView[2].z)
			// shadowLightPosition is broken in other dimensions. The current is equivalent to:
			// normalize(mat3(gbufferModelViewInverse) * shadowLightPosition + gbufferModelViewInverse[3].xyz)

			float rainDiff = rainStrength * 0.5;

			#ifdef SHD_ENABLE
				vec3 shadowCol = vec3(0);

				// If the area isn't shaded, apply shadow mapping
				if(NL > 0){
					// Get shadow pos
					vec3 feetPlayerPos = mat3(gbufferModelViewInverse) * toView(vec3(gl_FragCoord.xy / vec2(viewWidth, viewHeight), gl_FragCoord.z)) + gbufferModelViewInverse[3].xyz;
					vec3 shdPos = mat3(shadowProjection) * (mat3(shadowModelView) * feetPlayerPos + shadowModelView[3].xyz) + shadowProjection[3].xyz;
					
					// Bias mutilplier, adjusts according to the current shadow distance and resolution
					float biasAdjustMult = exp2(max(0.0, (shadowDistance - shadowMapResolution * 0.125) / shadowDistance));
					float distortFactor = getDistortFactor(shdPos.xy);
					
					// Apply bias according to normal in shadow space
					shdPos += mat3(shadowProjection) * (mat3(shadowModelView) * norm) * biasAdjustMult * biasAdjustMult * distortFactor * 0.5;
					shdPos = distort(shdPos, distortFactor) * 0.5 + 0.5;

					// Sample shadows
					#ifdef SHD_FILTER
						#if ANTI_ALIASING >= 2
							shadowCol = getShdFilter(shdPos, toRandPerFrame(texelFetch(noisetex, ivec2(gl_FragCoord.xy) & 255, 0).x, frameTimeCounter) * PI2);
						#else
							shadowCol = getShdFilter(shdPos, texelFetch(noisetex, ivec2(gl_FragCoord.xy) & 255, 0).x * PI2);
						#endif
					#else
						shadowCol = getShdTex(shdPos);
					#endif
				}

				totalDiffuse += (shadowCol * NL * (1.0 - rainDiff) + rainDiff) * pow(LIGHT_COL_DATA_BLOCK, vec3(GAMMA));
			#else
				totalDiffuse += (NL * (1.0 - rainDiff) + rainDiff) * pow(LIGHT_COL_DATA_BLOCK, vec3(GAMMA));
			#endif
		#endif

		return vec4(albedo.rgb * totalDiffuse, albedo.a);
	}
#else
	vec4 simpleShadingGbuffers(vec4 albedo){
		// Get lightmaps and add simple sky GI
		vec3 totalDiffuse = pow(SKY_COL_DATA_BLOCK * lmCoord.y, vec3(GAMMA)) +
			pow((lmCoord.x * BLOCKLIGHT_I * 0.00392156863) * vec3(BLOCKLIGHT_R, BLOCKLIGHT_G, BLOCKLIGHT_B), vec3(GAMMA)) +
			pow(AMBIENT_LIGHTING + nightVision * 0.5, GAMMA);

		#ifdef WORLD_LIGHT
			float NL = max(0.0, dot(norm, vec3(shadowModelView[0].z, shadowModelView[1].z, shadowModelView[2].z)));
			// also equivalent to:
			// vec3(0, 0, 1) * mat3(shadowModelView) = vec3(shadowModelView[0].z, shadowModelView[1].z, shadowModelView[2].z)
			// shadowLightPosition is broken in other dimensions. The current is equivalent to:
			// normalize(mat3(gbufferModelViewInverse) * shadowLightPosition + gbufferModelViewInverse[3].xyz)

			#ifdef SHD_ENABLE
				vec3 shadowCol = vec3(0);

				// If the area isn't shaded, apply shadow mapping
				if(NL > 0){
					// Cave light leak fix
					float caveFixShdFactor = isEyeInWater == 1 ? 1.0 : min(1.0, lmCoord.y * 2.0) * (1.0 - eyeBrightFact) + eyeBrightFact;

					// Get shadow pos
					vec3 feetPlayerPos = mat3(gbufferModelViewInverse) * toView(vec3(gl_FragCoord.xy / vec2(viewWidth, viewHeight), gl_FragCoord.z)) + gbufferModelViewInverse[3].xyz;
					vec3 shdPos = mat3(shadowProjection) * (mat3(shadowModelView) * feetPlayerPos + shadowModelView[3].xyz) + shadowProjection[3].xyz;
					
					// Bias mutilplier, adjusts according to the current shadow distance and resolution
					float biasAdjustMult = log2(max(4.0, shadowDistance - shadowMapResolution * 0.125)) * 0.25;
					float distortFactor = getDistortFactor(shdPos.xy);

					// Apply bias according to normal in shadow space
					shdPos += mat3(shadowProjection) * (mat3(shadowModelView) * norm) * distortFactor * biasAdjustMult;
					shdPos = distort(shdPos, distortFactor) * 0.5 + 0.5;

					// Sample shadows
					#ifdef SHD_FILTER
						#if ANTI_ALIASING >= 2
							shadowCol = getShdFilter(shdPos, toRandPerFrame(texelFetch(noisetex, ivec2(gl_FragCoord.xy) & 255, 0).x, frameTimeCounter) * PI2);
						#else
							shadowCol = getShdFilter(shdPos, texelFetch(noisetex, ivec2(gl_FragCoord.xy) & 255, 0).x * PI2);
						#endif
					#else
						shadowCol = getShdTex(shdPos) * caveFixShdFactor;
					#endif
				}
			#else
				// Sample fake shadows
				float shadowCol = smoothstep(0.94, 0.96, lmCoord.y);
			#endif

			float rainDiff = rainStrength * 0.5;
			totalDiffuse += (shadowCol * NL * shdFade * (1.0 - rainDiff) + lmCoord.y * lmCoord.y * rainDiff) * pow(LIGHT_COL_DATA_BLOCK, vec3(GAMMA));
		#endif

		return vec4(albedo.rgb * totalDiffuse, albedo.a);
	}
#endif