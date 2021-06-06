vec2 outlineOffsets[4] = vec2[4](
    vec2(1),
    vec2(1, -1),
    vec2(1, 0),
    vec2(0, 1)
);

vec3 getOutline(sampler2D depthTex, vec3 color, vec2 st){
    float pixOffSet = OUTLINE_PIX_SIZE / max(viewWidth, viewHeight);
    float depthOrigin = toView(texture2D(depthTex, st).x);
    float totalDepth, depth0, depth1 = 0.0; // maxDepth = 0.0;
    // float outLine = 1.0;

    for(int i = 0; i < 4; i++){
        vec2 offSets = outlineOffsets[i] * pixOffSet;
        depth0 = toView(texture2D(depthTex, st - offSets).x);
        depth1 = toView(texture2D(depthTex, st + offSets).x);

        // outLine *= saturate(1.0 - ((depth0 + depth1) - depthOrigin * 2.0) * 32.0 / depthOrigin);

        // maxDepth = max(depthOrigin, max(depth0, depth1));
        totalDepth += depth0 + depth1;
    }

    // Calculate the differences of the offsetted depths...
    float dDepth = totalDepth - depthOrigin * 8.0;

    return color * (1.0 + smootherstep(dDepth) * (OUTLINE_BRIGHTNESS - 1.0));
}