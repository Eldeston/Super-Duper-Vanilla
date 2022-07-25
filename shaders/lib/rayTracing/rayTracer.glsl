vec2 binarySearch(vec3 screenPosRayDir, vec3 startPos, int binarySearchSteps){
	for(int i = 0; i < binarySearchSteps; i++){
		screenPosRayDir *= 0.5;
		startPos += texture2D(depthtex0, startPos.xy).x < startPos.z ? -screenPosRayDir : screenPosRayDir;
	}

	return startPos.xy;
}

// This raytracer is so fast I swear...
// Based from Belmu's raytracer https://github.com/BelmuTM/NobleRT
// (it's basically an upgrade to Shadax's raytracer https://github.com/Shadax-stack/MinecraftSSR)
vec3 rayTraceScene(vec3 screenPos, vec3 viewPos, vec3 rayDir, float dither, int steps, int binarySearchSteps){
	// If hand, do simple, flipped reflections
	if(screenPos.z < 0.56){
		vec2 handScreenPos = toScreen(viewPos + rayDir * 128.0).xy;
		return vec3(handScreenPos, texture2D(depthtex0, handScreenPos).x != 1);
	}

	// Fix for the blob when player is near a surface. From Bálint#1673
	if(rayDir.z > 0 && rayDir.z >= -viewPos.z) return vec3(0);

	// Get screenspace rayDir
	vec3 screenPosRayDir = normalize(toScreen(viewPos + rayDir) - screenPos) / steps;
	// Add dithering to our "startPos"
	screenPos += screenPosRayDir * dither;

	// Screen pos is our startPos
	for(int i = 0; i < steps; i++){
		// We raytrace here
		screenPos += screenPosRayDir;
		if(screenPos.x <= 0 || screenPos.y <= 0 || screenPos.x >= 1 || screenPos.y >= 1) return vec3(0);
		float currDepth = texture2D(depthtex0, screenPos.xy).x;

		// Check intersection
		if(screenPos.z > currDepth && currDepth > 0.56){
			if(binarySearchSteps == 0) return vec3(screenPos.xy, currDepth != 1);
			return vec3(binarySearch(screenPosRayDir, screenPos, binarySearchSteps), currDepth != 1);
		}
	}
	
	return vec3(0);
}