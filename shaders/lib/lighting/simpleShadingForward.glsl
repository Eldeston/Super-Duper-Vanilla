#ifdef WORLD_LIGHT
	uniform float shdFade;
#endif

#ifdef CLOUDS
	vec4 simpleShadingGbuffers(vec4 albedo){
		// Get lightmaps and add simple sky GI
		vec3 totalDiffuse = toLinear(SKY_COL_DATA_BLOCK) +
			toLinear(AMBIENT_LIGHTING + nightVision * 0.5);

		#ifdef WORLD_LIGHT
			float NL = max(0.0, dot(vertexNormal, shdLightView)) * 0.6 + 0.4;

			float rainDiff = rainStrength * 0.5;

			#ifdef SHD_ENABLE
				vec3 shadowCol = vec3(0);

				// If the area isn't shaded, apply shadow mapping
				if(NL > 0){
					// Most of shadow pos is already calculated in vertex
					// Sample shadows
					#ifdef SHD_FILTER
						#if ANTI_ALIASING >= 2
							shadowCol = getShdFilter(distort(shdPos, distortFactor) * 0.5 + 0.5, toRandPerFrame(texelFetch(noisetex, ivec2(gl_FragCoord.xy) & 255, 0).x, frameTimeCounter) * PI2);
						#else
							shadowCol = getShdFilter(distort(shdPos, distortFactor) * 0.5 + 0.5, texelFetch(noisetex, ivec2(gl_FragCoord.xy) & 255, 0).x * PI2);
						#endif
					#else
						shadowCol = getShdTex(distort(shdPos, distortFactor) * 0.5 + 0.5);
					#endif
				}

				totalDiffuse += (shadowCol * NL * shdFade * (1.0 - rainDiff) + rainDiff) * toLinear(LIGHT_COL_DATA_BLOCK);
			#else
				totalDiffuse += (NL * shdFade * (1.0 - rainDiff) + rainDiff) * toLinear(LIGHT_COL_DATA_BLOCK);
			#endif
		#endif

		return vec4(albedo.rgb * totalDiffuse, albedo.a);
	}
#else
	vec4 simpleShadingGbuffers(vec4 albedo){
		// Get lightmaps and add simple sky GI
		vec3 totalDiffuse = toLinear(SKY_COL_DATA_BLOCK * lmCoord.y) +
			toLinear((lmCoord.x * BLOCKLIGHT_I * 0.00392156863) * vec3(BLOCKLIGHT_R, BLOCKLIGHT_G, BLOCKLIGHT_B)) +
			toLinear(AMBIENT_LIGHTING + nightVision * 0.5);

		#ifdef WORLD_LIGHT
			float NL = max(0.0, dot(vertexNormal, shdLightView));
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

					// Most of shadow pos is already calculated in vertex
					// Sample shadows
					#ifdef SHD_FILTER
						#if ANTI_ALIASING >= 2
							shadowCol = getShdFilter(distort(shdPos, distortFactor) * 0.5 + 0.5, toRandPerFrame(texelFetch(noisetex, ivec2(gl_FragCoord.xy) & 255, 0).x, frameTimeCounter) * PI2);
						#else
							shadowCol = getShdFilter(distort(shdPos, distortFactor) * 0.5 + 0.5, texelFetch(noisetex, ivec2(gl_FragCoord.xy) & 255, 0).x * PI2);
						#endif
					#else
						shadowCol = getShdTex(distort(shdPos, distortFactor) * 0.5 + 0.5);
					#endif

					shadowCol *= caveFixShdFactor;
				}
			#else
				// Sample fake shadows
				float shadowCol = smoothstep(0.94, 0.96, lmCoord.y);
			#endif

			float rainDiff = rainStrength * 0.5;
			totalDiffuse += (shadowCol * NL * shdFade * (1.0 - rainDiff) + lmCoord.y * lmCoord.y * rainDiff) * toLinear(LIGHT_COL_DATA_BLOCK);
		#endif

		return vec4(albedo.rgb * totalDiffuse, albedo.a);
	}
#endif