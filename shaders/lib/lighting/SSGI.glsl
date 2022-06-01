// Written by xirreal#0281 on ShaderLabs
vec3 cosWeightedRandHemisphereDir(vec3 norm, vec2 seed){
    // For TBN rotation
    vec3 uu = normalize(cross(norm, vec3(0, 1, 1)));
    vec3 vv = cross(uu, norm);

    float radius = sqrt(seed.y);
    float xOffset = radius * cos(PI2 * seed.x);
    float yOffset = radius * sin(PI2 * seed.x);
    float zOffset = sqrt(1.0 - seed.y);

    // Return direction with TBN applied
    // TBN * vec3(xOffset, yOffset, zOffset)
    return normalize(vec3(xOffset * uu + yOffset * vv + zOffset * norm));
}

vec3 getSSGICoord(vec3 viewPos, vec3 screenPos, vec3 gBMVNorm, vec2 dither){
    // Get reflected screenpos
	vec3 reflectedScreenPos = rayTraceScene(screenPos, viewPos, cosWeightedRandHemisphereDir(gBMVNorm, dither), dither.x, SSGI_STEPS, SSGI_BISTEPS);
    
    // Check if it's the sky and return nothing
    if(reflectedScreenPos.z < 0.5) return vec3(0);

    // Return SSGI coord
    return vec3(reflectedScreenPos.xy, 1);
}