// By Jessie#7257
vec3 generateUnitVector(vec2 hash) {
    hash.x *= PI2; hash.y = hash.y * 2.0 - 1.0;
    return vec3(vec2(sin(hash.x), cos(hash.x)) * sqrt(1.0 - hash.y * hash.y), hash.y);
}

vec3 getSSGICoord(vec3 viewPos, vec3 screenPos, vec3 gBMVNorm, vec2 dither){
    // Get reflected screenpos
	vec3 reflectedScreenPos = rayTraceScene(screenPos, viewPos, normalize(gBMVNorm + generateUnitVector(dither)), dither.x, SSGI_STEPS, SSGI_BISTEPS);
    
    // Check if it's the sky and return nothing
    if(reflectedScreenPos.z < 0.5) return vec3(0);

    // Return SSGI coord
    return vec3(reflectedScreenPos.xy, 1);
}