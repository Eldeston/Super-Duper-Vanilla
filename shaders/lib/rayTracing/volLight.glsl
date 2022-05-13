#ifdef VOL_LIGHT
#endif

#ifdef WORLD_LIGHT
	vec3 getGodRays(vec3 feetPlayerPos, float dither){
		// Return 0 if volumetric brightness is 0
		if(VOL_LIGHT_BRIGHTNESS == 0) return vec3(0);

		float totalFogDensity = FOG_TOTAL_DENSITY * ((isEyeInWater + rainStrength) * PI + 1.0);
		float dist = length(feetPlayerPos);
		float heightFade = 1.0;

		vec3 nFeetPlayerPos = feetPlayerPos / dist;

		// Fade VL, but do not apply to underwater VL
		if(isEyeInWater != 1){
			heightFade = fastSqrt(min(1.0, 1.0 - nFeetPlayerPos.y));
			heightFade *= heightFade * heightFade * heightFade * heightFade;
			heightFade = (1.0 - heightFade) * rainStrength * 0.25 + heightFade;
		}

		#if defined VOL_LIGHT && defined SHD_ENABLE
			// Fix for rays going too far from scene
			vec3 endPos = nFeetPlayerPos * (min(min(far, shadowDistance), dist) * 0.14285714);

			// vec3 endPos = feetPlayerPos * 0.14285714;
			vec3 startPos = endPos * dither;

			vec3 rayData = vec3(0);
			for(int x = 0; x < 7; x++){
				rayData += getShdTex(distort(mat3(shadowProjection) * (mat3(shadowModelView) * startPos + shadowModelView[3].xyz) + shadowProjection[3].xyz) * 0.5 + 0.5);
				startPos += endPos;
			}
			
			return rayData * ((1.0 - exp(-length(feetPlayerPos) * totalFogDensity)) * heightFade * 0.14285714);
		#else
			return vec3(heightFade * (1.0 - exp(-length(feetPlayerPos) * totalFogDensity)));
		#endif
	}
#endif