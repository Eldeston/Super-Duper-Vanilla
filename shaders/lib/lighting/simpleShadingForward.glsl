#ifdef WORLD_LIGHT
	uniform float shdFade;
#endif

#ifdef CLOUDS
	vec4 simpleShadingGbuffers(vec4 albedo, vec3 feetPlayerPos){
		// Get lightmaps and add simple sky GI
		vec3 totalDiffuse = skyCol + ambientLighting;

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
					vec3 shdPos = mat3(shadowProjection) * (mat3(shadowModelView) * feetPlayerPos + shadowModelView[3].xyz) + shadowProjection[3].xyz;
					float distortFactor = getDistortFactor(shdPos.xy);
					shdPos += mat3(shadowProjection) * (mat3(shadowModelView) * norm) * squared(exp2(max(0.0, (shadowDistance - shadowMapResolution * 0.125) / shadowDistance))) * distortFactor * 0.5;
					shdPos = distort(shdPos, distortFactor) * 0.5 + 0.5;

					#ifdef SHD_FILTER
						#if ANTI_ALIASING == 2
							shadowCol = getShdFilter(shdPos, toRandPerFrame(texture2D(noisetex, gl_FragCoord.xy * 0.03125).x, frameTimeCounter) * PI2) * shdFade;
						#else
							shadowCol = getShdFilter(shdPos, texture2D(noisetex, gl_FragCoord.xy * 0.03125).x * PI2) * shdFade;
						#endif
					#else
						shadowCol = getShdTex(shdPos) * shdFade;
					#endif
				}

				totalDiffuse += (NL * shadowCol * (1.0 - rainDiff) + rainDiff) * lightCol;
			#else
				totalDiffuse += (NL * (1.0 - rainDiff) + rainDiff) * lightCol;
			#endif
		#endif

		return vec4(albedo.rgb * totalDiffuse, albedo.a);
	}
#else
	vec4 simpleShadingGbuffers(vec4 albedo, vec3 feetPlayerPos){
		// Get lightmaps and add simple sky GI
		vec3 totalDiffuse = skyCol * lmCoord.y * lmCoord.y + ambientLighting + pow((lmCoord.x * BLOCKLIGHT_I * 0.00392156863) * vec3(BLOCKLIGHT_R, BLOCKLIGHT_G, BLOCKLIGHT_B), vec3(GAMMA));

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
					float caveFixShdFactor = isEyeInWater == 1 ? 1.0 : smoothstep(0.4, 0.8, lmCoord.y) * (1.0 - eyeBrightFact) + eyeBrightFact;

					vec3 shdPos = mat3(shadowProjection) * (mat3(shadowModelView) * feetPlayerPos + shadowModelView[3].xyz) + shadowProjection[3].xyz;
					float distortFactor = getDistortFactor(shdPos.xy);
					shdPos += mat3(shadowProjection) * (mat3(shadowModelView) * norm) * squared(exp2(max(0.0, (shadowDistance - shadowMapResolution * 0.125) / shadowDistance))) * distortFactor;
					shdPos = distort(shdPos, distortFactor) * 0.5 + 0.5;

					#ifdef SHD_FILTER
						#if ANTI_ALIASING == 2
							shadowCol = getShdFilter(shdPos, toRandPerFrame(texture2D(noisetex, gl_FragCoord.xy * 0.03125).x, frameTimeCounter) * PI2) * shdFade;
						#else
							shadowCol = getShdFilter(shdPos, texture2D(noisetex, gl_FragCoord.xy * 0.03125).x * PI2) * shdFade;
						#endif
					#else
						shadowCol = getShdTex(shdPos) * caveFixShdFactor * shdFade;
					#endif
				}
			#else
				float shadowCol = smoothstep(0.94, 0.96, lmCoord.y) * shdFade;
			#endif

			float rainDiff = rainStrength * 0.5;
			totalDiffuse += (NL * shadowCol * (1.0 - rainDiff) + lmCoord.y * lmCoord.y * rainDiff) * lightCol;
		#endif

		return vec4(albedo.rgb * totalDiffuse, albedo.a);
	}
#endif