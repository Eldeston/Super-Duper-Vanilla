const int steps = 32; // Steps [16 32 48 64]

vec3 binarySearch(vec3 clipPosRayDir, vec3 startPos){
	for(int y = 0; y < (steps / 8); y++){
		vec3 screenPos = startPos * 0.5 + 0.5;
		if(screenPos.x < 0.0 || screenPos.y < 0.0 || screenPos.x > 1.0 || screenPos.y > 1.0) break;

		float depth = texture2D(depthtex0, screenPos.xy).x;
		float dDepth = depth - screenPos.z;

		clipPosRayDir *= 0.5;
		startPos += dDepth < 0.0 ? -clipPosRayDir : clipPosRayDir;
	}
	return startPos;
}

vec3 getScreenPosReflections(vec3 screenPos, vec3 normal, vec3 dither, float roughness){
	vec3 clipPos = screenPos * 2.0 - 1.0;
	vec3 viewPos = toView(screenPos);
	vec3 rayDir = reflect(normalize(viewPos), normal) + dither * squared(roughness * roughness);

	vec3 viewPosWithRayDir = viewPos + rayDir;
	vec3 clipPosRayDir = toScreen(viewPosWithRayDir) * 2.0 - 1.0; // Put it back to clip space...
	clipPosRayDir = normalize(clipPosRayDir - clipPos);

	float stepSize = 2.0 / steps;
	clipPosRayDir *= stepSize;
	vec3 startPos = clipPos;

	for(int x = 0; x < steps; x++){
		startPos += clipPosRayDir;
		vec3 screenPos = startPos * 0.5 + 0.5;
		if(screenPos.x < 0.0 || screenPos.y < 0.0 || screenPos.x > 1.0 || screenPos.y > 1.0) break;
		float depth = texture2D(depthtex0, screenPos.xy).x;

		if(depth < screenPos.z) return vec3(binarySearch(clipPosRayDir, startPos).xy * 0.5 + 0.5, float(depth != 1.0));
		// if(dDepth < 0.0) return vec3(screenPos.xy, float(depth != 1.0));
	}
	return vec3(0.0);
}