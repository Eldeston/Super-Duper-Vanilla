// Screen space to view space perspective projection
vec3 getViewPos(in mat4 projectionInverse, in vec3 screenPos){
    vec3 viewPos = vec3(vec2(projectionInverse[0].x, projectionInverse[1].y) * (screenPos.xy * 2.0 - 1.0), -1);
    return viewPos / (projectionInverse[2].w * (screenPos.z * 2.0 - 1.0) + projectionInverse[3].w);
}

// Screen depth to view depth
float getViewDepth(in mat4 projectionInverse, in float screenDepth){
	return -1.0 / (projectionInverse[2].w * (screenDepth * 2.0 - 1.0) + projectionInverse[3].w);
}

// View space to screen space perspective projection
vec3 getScreenPos(in mat4 projection, in vec3 viewPos){
	// vec3 screenPos = vec3(projection[0].x, projection[1].y, projection[2].z) * viewPos;
	// return (vec3(screenPos.xy, screenPos.z + projection[3].z) / -viewPos.z) * 0.5 + 0.5;
    vec2 screenCoord = vec2(projection[0].x, projection[1].y) * viewPos.xy;
	return 0.5 - vec3(screenCoord.xy / viewPos.z, projection[3].z / viewPos.z + projection[2].z) * 0.5;
}

// View space to screen space coordinates perspective projection
vec2 getScreenCoord(in mat4 projection, in vec3 viewPos){
	vec2 screenCoord = vec2(projection[0].x, projection[1].y) * viewPos.xy;
	return 0.5 - (screenCoord.xy / viewPos.z) * 0.5;
}

// View depth to screen depth
float getScreenDepth(in mat4 projection, in float viewDepth){
    // ((projection[2].z * viewDepth + projection[3].z) / -viewDepth) * 0.5 + 0.5
	return 0.5 - (projection[3].z / viewDepth + projection[2].z) * 0.5;
}