#ifdef WORLD_LIGHT
	uniform float shdFade;
#endif

#ifdef CLOUDS
	vec4 simpleShadingGbuffers(vec4 albedo){
		// Get lightmaps and add simple sky GI
		vec3 totalDiffuse = toLinear(SKY_COL_DATA_BLOCK) +
			toLinear(AMBIENT_LIGHTING + nightVision * 0.5);

		#ifdef WORLD_LIGHT
			float NL = max(0.0, dot(vertexNormal, vec3(shdVertexView[0].z, shdVertexView[1].z, shdVertexView[2].z))) * 0.6 + 0.4;

			float rainDiff = rainStrength * 0.5;

			#ifdef SHD_ENABLE
				vec3 shadowCol = vec3(0);

				// If the area isn't shaded, apply shadow mapping
				if(NL > 0){
					// We already have shadow pos calculated in vertex so we'll use it
					
					// Bias mutilplier, adjusts according to the current shadow distance and resolution
					float biasAdjustMult = log2(max(4.0, shadowDistance - shadowMapResolution * 0.125)) * 0.25;
					float distortFactor = getDistortFactor(shdPos.xy);
					
					// Apply bias according to normal in shadow space
					vec3 newShdPos = shdPos + (mat3(shadowProjection) * (shdVertexView * vertexNormal)) * distortFactor * biasAdjustMult;
					newShdPos = distort(newShdPos, distortFactor) * 0.5 + 0.5;

					// Sample shadows
					#ifdef SHD_FILTER
						#if ANTI_ALIASING >= 2
							shadowCol = getShdFilter(newShdPos, toRandPerFrame(texelFetch(noisetex, ivec2(gl_FragCoord.xy) & 255, 0).x, frameTimeCounter) * PI2);
						#else
							shadowCol = getShdFilter(newShdPos, texelFetch(noisetex, ivec2(gl_FragCoord.xy) & 255, 0).x * PI2);
						#endif
					#else
						shadowCol = getShdTex(newShdPos);
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
			float NL = max(0.0, dot(vertexNormal, vec3(shdVertexView[0].z, shdVertexView[1].z, shdVertexView[2].z)));
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

					// We already have shadow pos calculated in vertex so we'll use it
					
					// Bias mutilplier, adjusts according to the current shadow distance and resolution
					float biasAdjustMult = log2(max(4.0, shadowDistance - shadowMapResolution * 0.125)) * 0.25;
					float distortFactor = getDistortFactor(shdPos.xy);

					// Apply bias according to normal in shadow space
					vec3 newShdPos = shdPos + mat3(shadowProjection) * (shdVertexView * vertexNormal) * distortFactor * biasAdjustMult;
					newShdPos = distort(newShdPos, distortFactor) * 0.5 + 0.5;

					// Sample shadows
					#ifdef SHD_FILTER
						#if ANTI_ALIASING >= 2
							shadowCol = getShdFilter(newShdPos, toRandPerFrame(texelFetch(noisetex, ivec2(gl_FragCoord.xy) & 255, 0).x, frameTimeCounter) * PI2);
						#else
							shadowCol = getShdFilter(newShdPos, texelFetch(noisetex, ivec2(gl_FragCoord.xy) & 255, 0).x * PI2);
						#endif
					#else
						shadowCol = getShdTex(newShdPos) * caveFixShdFactor;
					#endif
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