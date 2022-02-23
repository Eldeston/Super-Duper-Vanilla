const float sunPathRotation = 30.0; // Light angle [-60.0 -55.0 -50.0 -45.0 -40.0 -35.0 -30.0 -25.0 -20.0 -15.0 -10.0 -5.0 0.0 5.0 10.0 15.0 20.0 25.0 30.0 35.0 40.0 45.0 50.0 55.0 60.0]

#if defined SHD_ENABLE && defined WORLD_LIGHT
	// Enable filtering on shadows
	const bool shadowHardwareFiltering = true;
	const int shadowMapResolution = 1024; // Shadow map resolution. Increase for more resolution at the cost of performance. [1024 2048 3072 4096 5120 6144 7168 8192]

	const float shadowDistance = 160.0; // Shadow distance. Increase to stretch the shadow map to farther distances in blocks. It's recommended to match this setting with your render distance. [32.0 64.0 80.0 96.0 112.0 128.0 160.0 192.0 224.0 256.0 320.0 384.0 512.0 768.0 1024.0]
	const float shadowDistanceRenderMul = 1.0; // Hardcoded to be always on for maximum optimization.

	// Shadow bias (unused)
	const float shdBias = 0.02; // Don't go below the default value otherwise it'll mess up lighting

	// Shadow opaque
	uniform sampler2DShadow shadowtex0;

	#ifdef SHD_COL
		// Shadow w/o translucents
		uniform sampler2DShadow shadowtex1;

		// Shadow color
		uniform sampler2D shadowcolor0;
	#endif

	vec3 getShdTex(vec3 shdPos){
		#ifdef SHD_COL
			float shd0 = shadow2D(shadowtex0, shdPos).x;
			float shd1 = shadow2D(shadowtex1, shdPos).x - shd0;

			return texture2D(shadowcolor0, shdPos.xy).rgb * shd1 * (1.0 - shd0) + shd0;
		#else
			return shadow2D(shadowtex0, shdPos).xxx;
		#endif
	}

	vec3 getShdFilter(vec3 shdPos, float dither, float shdRcp){
		vec2 randVec = vec2(sin(dither), cos(dither)) * shdRcp;
		
		vec3 shdCol = getShdTex(vec3(shdPos.xy + randVec, shdPos.z));
		return (shdCol + getShdTex(vec3(shdPos.xy - randVec, shdPos.z))) * 0.5;
	}

	// Shadow function
	vec3 getShdMapping(vec3 shdPos, float dirLight, float dither){
		// If the area isn't shaded, apply shadow mapping
		if(dirLight > 0){
			float shdRcp = 1.0 / shadowMapResolution;
			
			float distortFactor = getDistortFactor(shdPos.xy);
			shdPos.xyz = distort(shdPos.xyz, distortFactor) * 0.5 + 0.5;
			shdPos.z -= (6.0 * shdRcp * distortFactor * distortFactor) / dirLight;

			#ifdef SHADOW_FILTER
				return getShdFilter(shdPos.xyz, dither * PI2, shdRcp);
			#else
				return getShdTex(shdPos.xyz);
			#endif
		}

		// Otherwise, return nothing
		return vec3(0);
	}
#endif