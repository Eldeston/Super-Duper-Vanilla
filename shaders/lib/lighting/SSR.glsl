vec4 getSSRCol(vec3 viewPos, vec3 screenPos, vec3 gBMVNorm, vec3 nDither, float roughness){
    // Reflected direction
	vec3 reflectedRayDir = reflect(normalize(viewPos), gBMVNorm) + nDither * squared(roughness * roughness);
	// Get reflected screenpos
	vec3 reflectedScreenPos = rayTraceScene(screenPos, viewPos, reflectedRayDir, SSR_STEPS, SSR_BISTEPS);
    // Transform coords to previous frame coords
	reflectedScreenPos.xy = toPrevScreenPos(reflectedScreenPos.xy);

	float mask = edgeVisibility(reflectedScreenPos.xy);
	// Sample reflections
	vec3 SSRCol = texture2D(colortex5, reflectedScreenPos.xy).rgb;
    // Transform it back to HDR and output SSR mask in the alpha channel
    return vec4(1.0 / (1.0 - SSRCol) - 1.0, reflectedScreenPos.z * mask);
}