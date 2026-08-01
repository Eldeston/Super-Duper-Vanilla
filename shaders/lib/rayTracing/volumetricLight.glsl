#define VOLUMETRIC_LIGHT_STEPS 7u

const float volumetricStepsInverse = 1.0 / VOLUMETRIC_LIGHT_STEPS;

vec3 getVolumetricLight(in vec3 nFeetPlayerPos, in float feetPlayerDist, in float fogFactor, in float borderFog, in float dither, in bool isSky){
	float totalFogDensity = FOG_TOTAL_DENSITY;

	#ifdef FORCE_DISABLE_WEATHER
		if(isEyeInWater != 0) totalFogDensity *= TAU;
    #else
		totalFogDensity *= isEyeInWater == 0 ? (rainStrength * PI + 1.0) : TAU;
    #endif

	float heightFade = 1.0;

	// Fade VL, but do not apply to underwater VL
	if(isEyeInWater == 0 && nFeetPlayerPos.y > 0){
		heightFade = squared(squared(1.0 - squared(nFeetPlayerPos.y)));
		if(isSky) heightFade *= heightFade;

		#ifndef WORLD_CUSTOM_SKYLIGHT
			#ifndef FORCE_DISABLE_WEATHER
				heightFade += (1.0 - heightFade) * max(1.0 - eyeBrightFact, rainStrength * 0.5);
			#else
				heightFade += (1.0 - heightFade) * (1.0 - eyeBrightFact);
			#endif
		#endif
	}

	float volumetricFogDensity = 1.0 - exp2(-feetPlayerDist * totalFogDensity);
	volumetricFogDensity = (volumetricFogDensity - fogFactor) * VOLUMETRIC_LIGHTING_STRENGTH + fogFactor;

	// Border fog
	#ifdef BORDER_FOG
		volumetricFogDensity = (volumetricFogDensity - 1.0) * borderFog + 1.0;
	#endif

	#if defined VOLUMETRIC_LIGHTING && defined SHADOW_MAPPING
		// Normalize then unormalize with feetPlayerDist and clamping it at minimum distance between far and current shadowDistance
		vec3 endPos = vec3(shadowProjection[0].x, shadowProjection[1].y, shadowProjection[2].z) * (mat3(shadowModelView) * nFeetPlayerPos);
		endPos *= min(min(borderFar, shadowDistance), feetPlayerDist) * volumetricStepsInverse;

		// Apply dithering added to the eyePlayerPos "camera" position converted to shadow clip space
		vec3 startPos = vec3(shadowProjection[0].x, shadowProjection[1].y, shadowProjection[2].z) * shadowModelView[3].xyz + endPos * dither;
		startPos.z += shadowProjection[3].z;

		vec3 volumeData = vec3(0);

		for(uint i = 0u; i < VOLUMETRIC_LIGHT_STEPS; i++){
			// No need to do anymore fancy matrix multiplications during the loop
			volumeData += getShdCol(vec3(startPos.xy / (length(startPos.xy) * 2.0 + 0.2), startPos.z * 0.1) + 0.5);
			// We continue tracing!
			startPos += endPos;
		}
		
		return volumeData * lightCol * (min(1.0, VOLUMETRIC_LIGHTING_STRENGTH + VOLUMETRIC_LIGHTING_STRENGTH * isEyeInWater) * squared(heightFade) * volumetricFogDensity * volumetricStepsInverse);
	#else
		if(isEyeInWater == 1) return lightCol * toLinear(fogColor) * (min(1.0, VOLUMETRIC_LIGHTING_STRENGTH * 2.0) * volumetricFogDensity);
		#ifdef WORLD_CUSTOM_SKYLIGHT
			else return lightCol * (volumetricFogDensity * VOLUMETRIC_LIGHTING_STRENGTH);
		#else
			else return lightCol * (squared(eyeBrightFact) * volumetricFogDensity * VOLUMETRIC_LIGHTING_STRENGTH);
		#endif
	#endif
}