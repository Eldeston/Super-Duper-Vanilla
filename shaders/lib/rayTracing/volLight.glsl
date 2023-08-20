vec3 getVolumetricLight(in vec3 feetPlayerPos, in float depth, in float dither){
	float feetPlayerDist = length(feetPlayerPos);
	vec3 nFeetPlayerPos = feetPlayerPos / feetPlayerDist;

	float totalFogDensity = FOG_TOTAL_DENSITY;

	#ifdef FORCE_DISABLE_WEATHER
		if(isEyeInWater != 0) totalFogDensity *= TAU;
    #else
		totalFogDensity *= isEyeInWater == 0 ? (rainStrength * PI + 1.0) : TAU;
    #endif

	float heightFade = 1.0;

	// Fade VL, but do not apply to underwater VL
	if(isEyeInWater == 0 && nFeetPlayerPos.y > 0){
		heightFade = squared(1.0 - squared(nFeetPlayerPos.y));
		if(depth == 1) heightFade = squared(heightFade * heightFade);

		#ifndef WORLD_CUSTOM_SKYLIGHT
			#ifndef FORCE_DISABLE_WEATHER
				heightFade += (1.0 - heightFade) * max(1.0 - eyeBrightFact, rainStrength * 0.5);
			#else
				heightFade += (1.0 - heightFade) * (1.0 - eyeBrightFact);
			#endif
		#endif
	}

	// Border fog
	// Modified Complementary border fog calculation, thanks Emin!
	#ifdef BORDER_FOG
		float volumetricFogDensity = 1.0 - exp2(-feetPlayerDist * totalFogDensity - exp2(feetPlayerDist / far * 21.0 - 18.0));
	#else
		float volumetricFogDensity = 1.0 - exp2(-feetPlayerDist * totalFogDensity);
	#endif

	// Apply adjustments
	volumetricFogDensity *= heightFade * shdFade;

	#if defined VOLUMETRIC_LIGHTING && defined SHADOW_MAPPING
		// Normalize then unormalize with feetPlayerDist and clamping it at minimum distance between far and current shadowDistance
		vec3 endPos = vec3(shadowProjection[0].x, shadowProjection[1].y, shadowProjection[2].z) * (mat3(shadowModelView) * (nFeetPlayerPos * min(min(far, shadowDistance), feetPlayerDist))) * 0.14285714;

		// Apply dithering added to the eyePlayerPos "camera" position converted to shadow clip space
		vec3 startPos = vec3(shadowProjection[0].x, shadowProjection[1].y, shadowProjection[2].z) * shadowModelView[3].xyz + endPos * dither;
		startPos.z += shadowProjection[3].z;

		vec3 rayData = vec3(0);
		for(int x = 0; x < 7; x++){
			// No need to do anymore fancy matrix multiplications during the loop
			rayData += getShdCol(vec3(startPos.xy / (length(startPos.xy) * 2.0 + 0.2), startPos.z * 0.1) + 0.5);
			// We continue tracing!
			startPos += endPos;
		}

		return lightCol * rayData * (min(1.0, VOLUMETRIC_LIGHTING_STRENGTH + VOLUMETRIC_LIGHTING_STRENGTH * isEyeInWater) * volumetricFogDensity * 0.14285714);
	#else
		if(isEyeInWater == 1) return lightCol * toLinear(fogColor) * (min(1.0, VOLUMETRIC_LIGHTING_STRENGTH * 2.0) * volumetricFogDensity);
		#ifdef WORLD_CUSTOM_SKYLIGHT
			else return lightCol * (volumetricFogDensity * VOLUMETRIC_LIGHTING_STRENGTH);
		#else
			else return lightCol * (volumetricFogDensity * eyeBrightFact * VOLUMETRIC_LIGHTING_STRENGTH);
		#endif
	#endif
}