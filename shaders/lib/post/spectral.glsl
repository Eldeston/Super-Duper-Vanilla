vec2 spectralOffsets[4] = vec2[4](
    vec2(1),
    vec2(1, -1),
    vec2(1, 0),
    vec2(0, 1)
);

float getSpectral(sampler2D mask, vec2 st, float pixSize){
    float pixOffSet = pixSize / max(viewWidth, viewHeight);
    float depthOrigin = texture2D(mask, st).x;
    float totalDepth = 0.0;

    for(int i = 0; i < 4; i++){
        vec2 offSets = spectralOffsets[i] * pixOffSet;
        float depth0 = texture2D(mask, st - offSets).x;
        float depth1 = texture2D(mask, st + offSets).x;

        totalDepth += depth0 + depth1;
    }

    // Calculate the differences of the offsetted depths...
    return abs(totalDepth - depthOrigin * 8.0);
}