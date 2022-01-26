vec2 spectralOffsets[2] = vec2[2](
    vec2(1),
    vec2(1, -1)
);

float getSpectral(sampler2D mask, vec2 st, float pixSize){
    float pixOffSet = pixSize / max(viewWidth, viewHeight);
    float depthOrigin = texture2D(mask, st).z;
    float totalDepth = 0.0;

    for(int i = 0; i < 2; i++){
        vec2 offSets = spectralOffsets[i] * pixOffSet;
        float depth0 = texture2D(mask, st - offSets).z;
        float depth1 = texture2D(mask, st + offSets).z;

        totalDepth += depth0 + depth1;
    }

    // Calculate the differences of the offsetted depths...
    return abs(totalDepth - depthOrigin * 4.0);
}