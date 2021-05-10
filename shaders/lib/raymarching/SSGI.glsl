const int GISteps = 32; // Steps [16 32 48 64]

vec3 getScreenPosGlobalIllumination(vec3 screenPos, vec3 viewPos, vec3 normal, vec3 dither){
	vec3 clipPos = screenPos * 2.0 - 1.0;
	vec3 rayDir = normal + dither;
	float stepSize = 2.0 / GISteps;

	vec3 viewPosWithRayDir = viewPos + rayDir;
	vec3 clipPosRayDir = toScreen(viewPosWithRayDir) * 2.0 - 1.0; // Put it back to clip space...
	clipPosRayDir = normalize(clipPosRayDir - clipPos) * stepSize;
	vec3 startPos = clipPos;

	for(int x = 0; x < GISteps; x++){
		startPos += clipPosRayDir;
		vec3 newScreenPos = startPos * 0.5 + 0.5;
		if(newScreenPos.x < 0.0 || newScreenPos.y < 0.0 || newScreenPos.x > 1.0 || newScreenPos.y > 1.0) return vec3(0.0);
		float depth = texture2D(depthtex0, newScreenPos.xy).x;

		if(depth < newScreenPos.z) return vec3(binarySearch(clipPosRayDir, startPos).xy * 0.5 + 0.5, depth != 1);
	}
	return vec3(0.0);
}