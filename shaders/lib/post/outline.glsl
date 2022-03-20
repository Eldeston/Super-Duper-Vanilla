vec2 edgeOffsets0[2] = vec2[2](
    vec2(1),
    vec2(1, -1)
);

float getOutline(vec3 screenPos, float depthOrigin, int pixSize){
    vec2 pixOffSet = pixSize / vec2(viewWidth, viewHeight);
    float totalDepth = 0.0;

    for(int i = 0; i < 2; i++){
        vec2 offSets = edgeOffsets0[i] * pixOffSet;
        float depth0 = toView(texture2D(depthtex0, screenPos.xy - offSets).x);
        float depth1 = toView(texture2D(depthtex0, screenPos.xy + offSets).x);

        totalDepth += depth0 + depth1;
    }

    // Calculate the differences of the offsetted depths...
    return smootherstep(totalDepth - depthOrigin * 4.0);
}

vec3 sampleDepthNorm(vec2 uv){
    return toView(texture2D(depthtex0, uv).x) * (texture2D(colortex1, uv).xyz * 2.0 - 1.0);
}

float getEdge(vec3 normal, vec3 screenPos, float depthOrigin, int pixSize){
    float pixOffSet = pixSize / max(viewWidth, viewHeight);

    vec3 totalDepthNorm = sampleDepthNorm(screenPos.xy + vec2(pixOffSet, 0));
    totalDepthNorm += sampleDepthNorm(screenPos.xy - vec2(pixOffSet, 0));
    totalDepthNorm += sampleDepthNorm(screenPos.xy + vec2(0, pixOffSet));
    totalDepthNorm += sampleDepthNorm(screenPos.xy - vec2(0, pixOffSet));

    return smootherstep(maxC(totalDepthNorm - depthOrigin * normal * 4.0));
}