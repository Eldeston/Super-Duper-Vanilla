#ifdef VOL_LIGHT
#endif

#ifdef WORLD_LIGHT
	vec3 getVolumetricLight(in vec3 nEyePlayerPos, in float viewDist, in float depth, in float dither){
		// Return 0 if volumetric brightness is 0
		if(VOL_LIGHT_BRIGHTNESS == 0) return vec3(0);

		float totalFogDensity = FOG_TOTAL_DENSITY * (isEyeInWater == 0 ? rainStrength * PI + 1.0 : TAU);
		float heightFade = 1.0;

		// Fade VL, but do not apply to underwater VL
		if(isEyeInWater != 1){
			heightFade = 1.0 - squared(max(0.0, nEyePlayerPos.y));
			heightFade = depth == 1 ? squared(squared(heightFade * heightFade)) : heightFade * heightFade;
			heightFade += (1.0 - heightFade) * rainStrength * 0.5;
		}

		// Border fog
		// Modified Complementary border fog calculation, thanks Emin!
		#ifdef BORDER_FOG
			float volumetricFogDensity = 1.0 - exp2(-viewDist * totalFogDensity - exp2(viewDist / far * 21.0 - 18.0));
		#else
			float volumetricFogDensity = 1.0 - exp2(-viewDist * totalFogDensity);
		#endif

		#if defined VOL_LIGHT && defined SHD_ENABLE
			// Normalize then unormalize with viewDist and clamping it at minimum distance between far and current shadowDistance
			vec3 endPos = mat3(shadowProjection) * (mat3(shadowModelView) * (nEyePlayerPos * min(min(far, shadowDistance), viewDist))) * 0.14285714;

			// Apply dithering added to the eyePlayerPos "camera" position converted to shadow clip space
			vec3 startPos = mat3(shadowProjection) * shadowModelView[3].xyz + shadowProjection[3].xyz + endPos * dither;
			
			vec3 rayData = vec3(0);
			for(int x = 0; x < 7; x++){
				// No need to do anymore fancy matrix multiplications during the loop
				rayData += getShdTex(distort(startPos) * 0.5 + 0.5);
				// We continue tracing!
				startPos += endPos;
			}
			
			return lightCol * rayData * (volumetricFogDensity * heightFade * 0.14285714);
		#else
			if(isEyeInWater == 1) return lightCol * toLinear(fogColor) * (volumetricFogDensity * heightFade);
			else return lightCol * (volumetricFogDensity * heightFade * eyeBrightFact);
		#endif
	}
#endif