const int steps = 32; // Steps [16 32 48 64]

vec3 binarySearch(vec3 clipPosRayDir, vec3 startPos){
	for(int y = 0; y < 4; y++){
		vec3 screenPos = startPos * 0.5 + 0.5;
		if(screenPos.x < 0.0 || screenPos.y < 0.0 || screenPos.x > 1.0 || screenPos.y > 1.0) break;\

		clipPosRayDir *= 0.5;
		startPos += texture2D(depthtex0, screenPos.xy).x < screenPos.z ? -clipPosRayDir : clipPosRayDir;
	}
	return startPos;
}

vec3 getScreenPosReflections(vec3 screenPos, vec3 viewPos, vec3 normal, vec3 dither, float roughness){
	vec3 clipPos = screenPos * 2.0 - 1.0;
	vec3 rayDir = reflect(normalize(viewPos), normal) + dither * squared(roughness * roughness);

	float stepSize = 2.0 / steps;

	vec3 viewPosWithRayDir = viewPos + rayDir;
	vec3 clipPosRayDir = toScreen(viewPosWithRayDir) * 2.0 - 1.0; // Put it back to clip space...
	clipPosRayDir = normalize(clipPosRayDir - clipPos) * stepSize;

	vec3 startPos = clipPos;

	for(int x = 0; x < steps; x++){
		startPos += clipPosRayDir;
		vec3 newScreenPos = startPos * 0.5 + 0.5;
		if(newScreenPos.x < 0.0 || newScreenPos.y < 0.0 || newScreenPos.x > 1.0 || newScreenPos.y > 1.0) return vec3(0.0);
		float depth = texture2D(depthtex0, newScreenPos.xy).x;

		if(depth < newScreenPos.z) return vec3(binarySearch(clipPosRayDir, startPos).xy * 0.5 + 0.5, int(depth != 1));
	}
	return vec3(0.0);
}