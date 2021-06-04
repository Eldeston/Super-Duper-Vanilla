vec3 binarySearch(vec3 clipPosRayDir, vec3 startPos, int binarySearchSteps){
	for(int y = 0; y < binarySearchSteps; y++){
		vec3 screenPos = startPos * 0.5 + 0.5;
		if(screenPos.x < 0 || screenPos.y < 0 || screenPos.x > 1 || screenPos.y > 1) break;

		clipPosRayDir *= 0.5;
		startPos += texture2D(depthtex0, screenPos.xy).x < screenPos.z ? -clipPosRayDir : clipPosRayDir;
	}
	return startPos;
}

vec3 rayTraceScene(vec3 screenPos, vec3 viewPos, vec3 rayDir, int steps, int binarySearchSteps){
	// We'll also use this as a start position
	vec3 clipPos = screenPos * 2.0 - 1.0;

	if(clipPos.z < MC_HAND_DEPTH) return vec3(0);

	vec3 viewPosWithRayDir = viewPos + rayDir;
	vec3 clipPosRayDir = toScreen(viewPosWithRayDir) * 2.0 - 1.0; // Put it back to clip space...
	clipPosRayDir = normalize(clipPosRayDir - clipPos) * (2.0 / steps);

	// vec3 startPos = clipPos;
	for(int x = 0; x < steps; x++){
		clipPos += clipPosRayDir;
		vec3 newScreenPos = clipPos * 0.5 + 0.5;
		if(newScreenPos.x < 0 || newScreenPos.y < 0 || newScreenPos.x > 1 || newScreenPos.y > 1) return vec3(0);
		float depth = texture2D(depthtex0, newScreenPos.xy).x;

		if(newScreenPos.z > depth && (newScreenPos.z - depth) < MC_HAND_DEPTH){
			if(binarySearchSteps == 0) return vec3(clipPos.xy * 0.5 + 0.5, depth != 1);
			else return vec3(binarySearch(clipPosRayDir, clipPos, binarySearchSteps).xy * 0.5 + 0.5, depth != 1);
		}
		// if(newScreenPos.z > depth && (newScreenPos.z - depth) < 0.001) // Causes reflections to make stripes...
	}
	return vec3(0);
}