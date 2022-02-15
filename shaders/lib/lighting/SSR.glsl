vec4 getSSRCol(vec3 viewPos, vec3 screenPos, vec3 gBMVNorm){
    // Reflected direction
	vec3 reflectedRayDir = reflect(normalize(viewPos), gBMVNorm);
	// Get reflected screenpos
	vec3 reflectedScreenPos = rayTraceScene(screenPos, viewPos, reflectedRayDir, SSR_STEPS, SSR_BISTEPS);

	/*
	float dist = length(toScreenSpacePos(reflectedScreenPos.xy, depthtex0) - viewPos);
	dist = 1.0 - exp(-0.125 * (1.0 - smoothness) * dist);
	float lod = log2(viewHeight / 8.0 * (1.0 - smoothness) * dist);
	*/
	
	if(reflectedScreenPos.z != 0){
		#ifdef PREVIOUS_FRAME
			// Transform coords to previous frame coords
			reflectedScreenPos.xy = toPrevScreenPos(reflectedScreenPos.xy);
			// Sample reflections
			vec3 SSRCol = texture2D(colortex5, reflectedScreenPos.xy).rgb;
			// Return color and output SSR mask in the alpha channel
			return vec4(SSRCol, edgeVisibility(reflectedScreenPos.xy));
		#else
			// Return sample, return color, and output SSR mask in the alpha channel
			return vec4(texture2D(gcolor, reflectedScreenPos.xy).rgb, edgeVisibility(reflectedScreenPos.xy));
		#endif
	}
	
	return vec4(0);
}