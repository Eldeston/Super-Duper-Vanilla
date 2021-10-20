vec2 edgeOffsets0[2] = vec2[2](
    vec2(1),
    vec2(1, -1)
);

float getOutline(sampler2D depthTex, vec3 screenPos, float pixSize){
    float pixOffSet = pixSize / max(viewWidth, viewHeight);
    float depthOrigin = toView(screenPos.z);
    float totalDepth = 0.0;

    for(int i = 0; i < 2; i++){
        vec2 offSets = edgeOffsets0[i] * pixOffSet;
        float depth0 = toView(texture2D(depthTex, screenPos.xy - offSets).x);
        float depth1 = toView(texture2D(depthTex, screenPos.xy + offSets).x);

        totalDepth += depth0 + depth1;
    }

    // Calculate the differences of the offsetted depths...
    return smootherstep(totalDepth - depthOrigin * 4.0);
}

vec2 edgeOffsets1[2] = vec2[2](
    vec2(1, 0),
    vec2(0, 1)
);

float getEdge(sampler2D depthTex, vec3 screenPos, float pixSize){
    float pixOffSet = pixSize / max(viewWidth, viewHeight);
    float depthOrigin = toView(screenPos.z);

    for(int i = 0; i < 2; i++){
        vec2 offSets = edgeOffsets1[i] * pixOffSet;
        float depth0 = toView(texture2D(depthTex, screenPos.xy - offSets).x);
        float depth1 = toView(texture2D(depthTex, screenPos.xy + offSets).x);

        if(abs((depthOrigin - depth0) - (depth1 - depthOrigin)) > -depthOrigin * 0.005) return 1.0;
    }

    return 0.0;
}