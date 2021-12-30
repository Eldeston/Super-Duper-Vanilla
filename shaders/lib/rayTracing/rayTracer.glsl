vec3 binarySearch(vec3 screenPosRayDir, vec3 startPos, int binarySearchSteps){
	for(int y = 0; y < binarySearchSteps; y++){
		vec3 screenPos = startPos;
		if(screenPos.x < 0 || screenPos.y < 0 || screenPos.x > 1 || screenPos.y > 1) break;

		screenPosRayDir *= 0.5;
		startPos += texture2D(depthtex0, screenPos.xy).x < screenPos.z ? -screenPosRayDir : screenPosRayDir;
	}

	return startPos;
}

// This raytracer is so fast I swear...
vec3 rayTraceScene(vec3 screenPos, vec3 viewPos, vec3 rayDir, int steps, int binarySearchSteps){
	// If hand, do simple, flipped reflections
	if((screenPos.z * 2.0 - 1.0) < MC_HAND_DEPTH){
		vec3 handScreenPos = toScreenSpacePos(toScreen(viewPos + rayDir * 128.0).xy);
		return vec3(handScreenPos.xy, handScreenPos.z != 1);
	}

	// Get screenspace rayDir
	vec3 screenPosRayDir = normalize(toScreen(viewPos + rayDir) - screenPos) * (2.0 / steps);

	// Screen pos is our startPos
	for(int x = 0; x < steps; x++){
		// We raytrace here
		screenPos += screenPosRayDir;
		if(screenPos.x < 0 || screenPos.y < 0 || screenPos.x > 1 || screenPos.y > 1) return vec3(0);
		float currDepth = texture2D(depthtex0, screenPos.xy).x;

		if(screenPos.z >= currDepth && (screenPos.z - currDepth) < MC_HAND_DEPTH){
			if(binarySearchSteps == 0) return vec3(screenPos.xy, currDepth != 1);
			return vec3(binarySearch(screenPosRayDir, screenPos, binarySearchSteps).xy, currDepth != 1);
		}
	}
	
	return vec3(0);
}