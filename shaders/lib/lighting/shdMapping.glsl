#ifdef WORLD_LIGHT
	#ifdef SHD_ENABLE
		// Enable filtering on shadows
		const bool shadowHardwareFiltering = true;

		const float shadowDistanceRenderMul = 1.0; // Hardcoded to be always 1.0 for maximum optimization.
		const float entityShadowDistanceMul = 0.5; // Renders the entity shadows at half shadowDistance. Iris only.

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
				// Sample shadows
				float shd0 = shadow2D(shadowtex0, shdPos).x;
				// If not in shadow, return "white"
				if(shd0 == 1) return vec3(1);

				// Sample opaque only shadows
				float shd1 = shadow2D(shadowtex1, shdPos).x;
				// If not in shadow return full shadow color
				if(shd1 != 0) return texelFetch(shadowcolor0, ivec2(shdPos.xy * shadowMapResolution), 0).rgb * shd1 * (1.0 - shd0) + shd0;
				// Otherwise, return "black"
				return vec3(0);
			#else
				// Sample shadows and return directly
				return shadow2D(shadowtex0, shdPos).xxx;
			#endif
		}

		vec3 getShdFilter(vec3 shdPos, float dither){
			vec2 randVec = vec2(cos(dither), sin(dither)) / shadowMapResolution;
			return (getShdTex(vec3(shdPos.xy + randVec, shdPos.z)) + getShdTex(vec3(shdPos.xy - randVec, shdPos.z))) * 0.5;
		}
	#endif
#endif