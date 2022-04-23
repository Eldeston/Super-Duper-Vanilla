vec4 getSSRCol(vec3 viewPos, vec3 screenPos, vec3 gBMVNorm, float dither){
	// Get reflected screenpos
	vec3 reflectedScreenPos = rayTraceScene(screenPos, viewPos, reflect(normalize(viewPos), gBMVNorm), dither, SSR_STEPS, SSR_BISTEPS);
	
	// Check if it's the sky and return nothing
	if(reflectedScreenPos.z < 0.5) return vec4(0);

	#ifdef PREVIOUS_FRAME
		// Transform coords to previous frame coords, sample color and return
		return vec4(texture2D(colortex5, toPrevScreenPos(reflectedScreenPos.xy)).rgb, 1);
	#else
		// Sample color and return
		return vec4(texture2D(gcolor, reflectedScreenPos.xy).rgb, 1);
	#endif
}