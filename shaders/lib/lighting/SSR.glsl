const float rayDistance = 192.0; // Distance [64.0 80.0 96.0 112.0 128.0]
const int steps = 32; // Steps [16 32 48 64]

vec3 binarySearch(inout vec3 result, vec3 refineDir){
	for(int y = 0; y < (steps / 8); y++){
		vec2 screenQuery = toScreen(result).xy;
		if(screenQuery.x < 0.0 || screenQuery.y < 0.0 || screenQuery.x > 1.0 || screenQuery.y > 1.0) break;

		bool hit = result.z < (gbufferProjectionInverse[3].z / (gbufferProjectionInverse[2].w * (texture2D(depthtex0, screenQuery).r * 2.0 - 1.0) + gbufferProjectionInverse[3].w));
		result += hit ? -refineDir : refineDir;
		refineDir *= 0.5;
	}
	return result;
}

vec3 getScreenSpaceCoords(vec3 st, vec3 normal){
	vec3 startPos = toLocal(st);
	vec3 startDir = normalize(reflect(normalize(startPos), normal));

	vec3 endPos = startDir * rayDistance; // startPos + (startDir * maxDistance)
	vec3 result = startPos + endPos;
	vec3 hitPos = startPos;
	
	float stepSize = 1.0 / float(steps);
	endPos *= stepSize;
	bool hit0 = false;

	for(int x = 0; x < steps; x++){
		hitPos += endPos;
		vec2 screenQuery = toScreen(hitPos).xy;
		if(screenQuery.x < 0.0 || screenQuery.y < 0.0 || screenQuery.x > 1.0 || screenQuery.y > 1.0) break;
		hit0 = hitPos.z < (gbufferProjectionInverse[3].z / (gbufferProjectionInverse[2].w * (texture2D(depthtex0, screenQuery).x * 2.0 - 1.0) + gbufferProjectionInverse[3].w));

		if(hit0) result = hitPos;
		if(hit0) break;
	}

	result = binarySearch(result, startDir);

	result = toScreen(result);
	vec2 maskUv = result.xy - 0.5;
	float maskEdge = smoothstep(0.2, 0.0, length(maskUv * maskUv * maskUv));
	return vec3(result.xy, float(hit0) * maskEdge * smoothstep(0.64, 0.56, normal.z));
}