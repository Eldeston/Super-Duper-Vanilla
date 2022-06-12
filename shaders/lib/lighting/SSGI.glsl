vec3 getSSGICoord(vec3 viewPos, vec3 screenPos, vec3 gBMVNorm, vec2 dither){
    // Get reflected screenpos
	vec3 reflectedScreenPos = rayTraceScene(screenPos, viewPos, normalize(gBMVNorm + generateUnitVector(dither)), dither.x, SSGI_STEPS, SSGI_BISTEPS);
    
    // Check if it's the sky and return nothing
    if(reflectedScreenPos.z < 0.5) return vec3(0);

    // Return SSGI coord
    return vec3(reflectedScreenPos.xy, 1);
}