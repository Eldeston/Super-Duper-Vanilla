// Written by xirreal#0281 on ShaderLabs
vec3 cosWeightedRandHemisphereDir(vec3 norm, vec2 seed){
    vec2 r = getRand2(seed * 8.0);
    vec3 uu = normalize(cross(norm, vec3(0, 1, 1)));
    vec3 vv = cross(uu, norm);

    float ra = sqrt(r.y);
    float rx = ra * cos(6.2831 * r.x);
    float ry = ra * sin(6.2831 * r.x);
    float rz = sqrt(1.0 - r.y);
    vec3  rr = vec3(rx * uu + ry * vv + rz * norm);

    return normalize(rr);
}

vec3 getSSGICol(vec3 viewPos, vec3 screenPos, vec3 gBMVNorm, vec2 dither){
    // Get reflected screenpos
	vec3 reflectedScreenPos = rayTraceScene(screenPos, viewPos, cosWeightedRandHemisphereDir(gBMVNorm, dither), dither.x, SSGI_STEPS, SSGI_BISTEPS);
    
    if(reflectedScreenPos.z > 0){
        #ifdef PREVIOUS_FRAME
            // Transform coords to previous frame coords
            reflectedScreenPos.xy = toPrevScreenPos(reflectedScreenPos.xy);
            // Sample color and return
            return texture2D(colortex5, reflectedScreenPos.xy).rgb;
        #else
            // Sample color and return
            return texture2D(gcolor, reflectedScreenPos.xy).rgb;
        #endif
    }

    return vec3(0);
}