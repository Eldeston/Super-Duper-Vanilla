vec4 getSSRCol(vec3 viewPos, vec3 screenPos, vec3 gBMVNorm, float dither){
	// Get reflected screenpos
	vec3 reflectedScreenPos = rayTraceScene(screenPos, viewPos, reflect(normalize(viewPos), gBMVNorm), dither, SSR_STEPS, SSR_BISTEPS);
	
	// Check if it's the sky and return nothing
	if(reflectedScreenPos.z == 0) return vec4(0);

	#ifdef PREVIOUS_FRAME
		// Transform coords to previous frame coords
		reflectedScreenPos.xy = toPrevScreenPos(reflectedScreenPos.xy);
		// Return color and output SSR mask in the alpha channel
		return vec4(texture2D(colortex5, reflectedScreenPos.xy).rgb, edgeVisibility(reflectedScreenPos.xy));
	#else
		// Return color and output SSR mask in the alpha channel
		return vec4(texture2D(gcolor, reflectedScreenPos.xy).rgb, edgeVisibility(reflectedScreenPos.xy));
	#endif
}