vec2 binarySearch(in vec3 screenPosRayDir, in vec3 startPos, in int binarySearchSteps){
	for(int i = 0; i < binarySearchSteps; i++){
		screenPosRayDir *= 0.5;
		startPos += textureLod(depthtex0, startPos.xy, 0).x < startPos.z ? -screenPosRayDir : screenPosRayDir;
	}

	return startPos.xy;
}

// This raytracer is so fast I swear...
// Based from Belmu's raytracer https://github.com/BelmuTM/NobleRT
// (it's basically an upgrade to Shadax's raytracer https://github.com/Shadax-stack/MinecraftSSR)
vec3 rayTraceScene(in vec3 screenPos, in vec3 viewPos, in vec3 rayDir, in float dither, in int steps, in int binarySearchSteps){
	// If hand, do simple, flipped reflections
	if(screenPos.z < 0.56){
		vec2 handScreenPos = toScreenCoord(viewPos + rayDir * 128.0);
		return vec3(handScreenPos, textureLod(depthtex0, handScreenPos, 0).x != 1);
	}

	// Fix for the blob when player is near a surface. From Bálint#1673
	if(rayDir.z > -viewPos.z) return vec3(0);

	// Get screenspace rayDir
	vec3 screenPosRayDir = fastNormalize(toScreen(viewPos + rayDir) - screenPos) / steps;
	// Add dithering to our "startPos"
	screenPos += screenPosRayDir * dither;

	// Screen pos is our startPos
	for(int i = 0; i < steps; i++){
		// We raytrace here
		screenPos += screenPosRayDir;
		if(screenPos.x < 0 || screenPos.y < 0 || screenPos.x > 1 || screenPos.y > 1) return vec3(0);
		float currDepth = textureLod(depthtex0, screenPos.xy, 0).x;

		// Check intersection
		if(screenPos.z > currDepth && currDepth > 0.56){
			if(binarySearchSteps == 0) return vec3(screenPos.xy, currDepth != 1);
			return vec3(binarySearch(screenPosRayDir, screenPos, binarySearchSteps), currDepth != 1);
		}
	}
	
	return vec3(0);
}