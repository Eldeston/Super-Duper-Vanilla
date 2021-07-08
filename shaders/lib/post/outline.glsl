vec2 outlineOffsets[4] = vec2[4](
    vec2(1),
    vec2(1, -1),
    vec2(1, 0),
    vec2(0, 1)
);

float getOutline(sampler2D depthTex, vec3 screenPos, float pixSize){
    float pixOffSet = pixSize / max(viewWidth, viewHeight);
    float depthOrigin = toView(screenPos.z);
    float totalDepth = 0.0;

    for(int i = 0; i < 4; i++){
        vec2 offSets = outlineOffsets[i] * pixOffSet;
        float depth0 = toView(texture2D(depthTex, screenPos.xy - offSets).x);
        float depth1 = toView(texture2D(depthTex, screenPos.xy + offSets).x);

        totalDepth += depth0 + depth1;
    }

    // Calculate the differences of the offsetted depths...
    float dDepth = totalDepth - depthOrigin * 8.0;

    return smootherstep(dDepth);
}

float getSpectral(sampler2D mask, vec2 st, float pixSize){
    float pixOffSet = pixSize / max(viewWidth, viewHeight);
    float depthOrigin = texture2D(mask, st).y;
    float totalDepth = 0.0;

    for(int i = 0; i < 4; i++){
        vec2 offSets = outlineOffsets[i] * pixOffSet;
        float depth0 = texture2D(mask, st - offSets).y;
        float depth1 = texture2D(mask, st + offSets).y;

        totalDepth += depth0 + depth1;
    }

    // Calculate the differences of the offsetted depths...
    return abs(totalDepth - depthOrigin * 8.0);
}