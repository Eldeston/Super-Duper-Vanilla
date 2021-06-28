vec4 getSSRCol(vec3 viewPos, vec3 screenPos, vec3 gBMVNorm){
    // Reflected direction
	vec3 reflectedRayDir = reflect(normalize(viewPos), gBMVNorm);
	// Get reflected screenpos
	vec3 reflectedScreenPos = rayTraceScene(screenPos, viewPos, reflectedRayDir, SSR_STEPS, SSR_BISTEPS);
    // Transform coords to previous frame coords
	// reflectedScreenPos.xy = toPrevScreenPos(reflectedScreenPos.xy);

	// Sample reflections
	vec3 SSRCol = texture2D(gcolor, reflectedScreenPos.xy).rgb;
    // Return color and output SSR mask in the alpha channel
    return vec4(max(SSRCol, vec3(0)), reflectedScreenPos.z * edgeVisibility(reflectedScreenPos.xy));
}