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