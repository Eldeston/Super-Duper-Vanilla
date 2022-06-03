ivec2 edgeOffsets0[2] = ivec2[2](
    ivec2(1),
    ivec2(1, -1)
);

float getOutline(ivec2 iUv, float depthOrigin, int pixSize){
    float totalDepth = 0.0;

    for(int i = 0; i < 2; i++){
        ivec2 offSets = edgeOffsets0[i] * pixSize;
        float depth0 = toView(texelFetch(depthtex0, iUv - offSets, 0).x);
        float depth1 = toView(texelFetch(depthtex0, iUv + offSets, 0).x);

        totalDepth += depth0 + depth1;
    }

    // Calculate the differences of the offsetted depths...
    return smootherstep(totalDepth - depthOrigin * 4.0);
}