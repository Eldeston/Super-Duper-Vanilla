vec3 getSSRCoord(vec3 viewPos, vec3 screenPos, vec3 gBMVNorm, float dither){
	// Get reflected screenpos
	vec3 reflectedScreenPos = rayTraceScene(screenPos, viewPos, reflect(normalize(viewPos), gBMVNorm), dither, SSR_STEPS, SSR_BISTEPS);
	
	// Check if it's the sky and return nothing
	if(reflectedScreenPos.z < 0.5) return vec3(0);

	// Return SSR coord
	return vec3(reflectedScreenPos.xy, 1);
}