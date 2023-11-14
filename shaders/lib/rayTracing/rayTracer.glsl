vec2 binarySearch(in vec3 screenPosRayDir, in vec3 startPos){
	for(int i = 0; i < RAYTRACER_BISTEPS; i++){
		screenPosRayDir *= 0.5;
		startPos += textureLod(depthtex0, startPos.xy, 0).x < startPos.z ? -screenPosRayDir : screenPosRayDir;
	}

	return startPos.xy;
}

// This raytracer is so fast I swear...
// Based from Belmu's raytracer https://github.com/BelmuTM/NobleRT
// (it's basically an upgrade to Shadax's raytracer https://github.com/Shadax-stack/MinecraftSSR)
vec3 raytraceScene(in vec3 screenPos, in vec3 viewPos, in vec3 rayDir, in float dither){
	// Fix for the blob when player is near a surface. From Bálint#1673
	if(rayDir.z > -viewPos.z) return vec3(0);

	// Get screenspace rayDir
	const float rayTraceSteps = 1.0 / RAYTRACER_STEPS;
	vec3 screenPosRayDir = fastNormalize(getScreenPos(gbufferProjection, viewPos + rayDir) - screenPos) * rayTraceSteps;

	// Add dithering to our "startPos"
	screenPos += screenPosRayDir * dither;

	// screenPos is startPos
	for(int i = 0; i < RAYTRACER_STEPS; i++){
		// We raytrace here
		screenPos += screenPosRayDir;
		if(screenPos.x < 0 || screenPos.y < 0 || screenPos.x > 1 || screenPos.y > 1) return vec3(0);
		float currDepth = textureLod(depthtex0, screenPos.xy, 0).x;

		// Check intersection
		if(screenPos.z > currDepth && currDepth > 0.56)
			#if RAYTRACER_BISTEPS != 0
				return vec3(binarySearch(screenPosRayDir, screenPos), currDepth != 1);
			#else
				return vec3(screenPos.xy, currDepth != 1);
			#endif
	}
	
	return vec3(0);
}