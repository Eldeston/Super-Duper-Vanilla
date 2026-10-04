#if defined DISTANT_HORIZONS || defined VOXY
	#define LOD_ACTIVE
#endif

#ifdef SSR
vec3 getFakeSSRCoord(in vec3 viewPos, in vec3 reflectViewDir){
	vec3 reflectDirF = viewPos + reflectViewDir * borderFar;
	if(reflectDirF.z < viewPos.z){
		vec3 SSRDH = getScreenPos(gbufferProjection, reflectDirF);
		if(clamp(SSRDH.xy, 0.0, 1.0) == SSRDH.xy && getDepthTex(SSRDH.xy) != 1.0) return vec3(SSRDH.xy, 1.0);
	}
	return vec3(0.0);
}
#endif

vec3 getDeferredReflection(in vec3 screenPos, in vec3 viewPos, in vec3 reflectViewDir, in float ditherZ, in float NV, in bool realSky){
	#ifdef SSR
		#ifdef LOD_ACTIVE
			vec3 SSRCoord = (!realSky && NV > 0.0) ? rayTraceScene(screenPos, viewPos, reflectViewDir, ditherZ) : vec3(0.0);

			if(!realSky && SSRCoord.z < 0.5){
		#else
			vec3 SSRCoord = (NV > 0.0) ? rayTraceScene(screenPos, viewPos, reflectViewDir, ditherZ) : vec3(0.0);

			if(SSRCoord.z < 0.5){
		#endif
				vec3 fakeCoord = getFakeSSRCoord(viewPos, reflectViewDir);
				if(fakeCoord.z > 0.5) SSRCoord = fakeCoord;
			}

		#ifdef PREVIOUS_FRAME
			return SSRCoord.z < 0.5 ? getSkyReflection(reflectViewDir) : textureLod(colortex5, getPrevScreenCoord(SSRCoord.xy), 0).rgb;
		#else
			return SSRCoord.z < 0.5 ? getSkyReflection(reflectViewDir) : textureLod(colortex4, SSRCoord.xy, 0).rgb;
		#endif
	#else
		return getSkyReflection(reflectViewDir);
	#endif
}

vec3 complexShadingDeferred(in vec3 sceneCol, in vec3 screenPos, in vec3 viewPos, in vec3 normal, in vec3 albedo, in vec3 dither, in float viewDotInvSqrt, in float metallic, in float smoothness, in bool realSky, in bool isWater){
	#if defined ROUGH_REFLECTIONS || defined SSGI
		vec3 noiseUnitVector = generateUnitVector(dither.xy);
	#endif

	// Calculate SSGI
	#ifdef SSGI
		vec3 SSGIcoord = rayTraceScene(screenPos, viewPos, generateCosineVector(normal, noiseUnitVector), dither.z);

		#ifdef PREVIOUS_FRAME
			if(SSGIcoord.z > 0.5) sceneCol += albedo * textureLod(colortex5, getPrevScreenCoord(SSGIcoord.xy), 0).rgb;
		#else
			if(SSGIcoord.z > 0.5) sceneCol += albedo * textureLod(colortex4, SSGIcoord.xy, 0).rgb;
		#endif
	#endif

	// If smoothness is 0, return immediately
	if(smoothness < 0.005) return sceneCol;

	#ifdef ROUGH_REFLECTIONS
		normal = generateCosineVector(normal, noiseUnitVector * (squared(1.0 - smoothness) * 0.5));
	#endif

	vec3 nViewPos = viewPos * viewDotInvSqrt;
	float NV = dot(normal, -nViewPos);
	vec3 reflectViewDir = nViewPos + (2.0 * NV) * normal;

	vec3 reflectCol = getDeferredReflection(screenPos, viewPos, reflectViewDir, dither.z, NV, realSky);
	reflectCol = clamp(reflectCol, vec3(0.0), vec3(16.0));

	#if WATER_STYLE == 1
		// For vanilla water, make reflections softer so the vibrant water body
		// and modded water effects (wakes, splash particles, foam) pop and feel at home!
		if(isWater) reflectCol *= 0.30;
	#endif

	float smoothCosTheta = NV > 0 ? exp2(-9.28 * NV) * smoothness : smoothness;
	float oneMinusCosTheta = smoothness - smoothCosTheta;

	if(metallic <= 0.9) return sceneCol + reflectCol * (smoothCosTheta + metallic * oneMinusCosTheta);
	return sceneCol + reflectCol * (smoothCosTheta + albedo * oneMinusCosTheta);
}

// Overload for non-water surfaces (e.g. deferred1.glsl terrain PBR)
vec3 complexShadingDeferred(in vec3 sceneCol, in vec3 screenPos, in vec3 viewPos, in vec3 normal, in vec3 albedo, in vec3 dither, in float viewDotInvSqrt, in float metallic, in float smoothness, in bool realSky){
	return complexShadingDeferred(sceneCol, screenPos, viewPos, normal, albedo, dither, viewDotInvSqrt, metallic, smoothness, realSky, false);
}