float getOutline(in ivec2 iUv, in float depthOrigin, in int pixSize){
    ivec2 topRightCorner = iUv - pixSize;
    ivec2 bottomLeftCorner = iUv + pixSize;

    // (1.0 - screenPos.z) / near
    // near / (1.0 - screenPos.z)

    depthOrigin = near / (1.0 - depthOrigin);

    float depth0 = near / (1.0 - texelFetch(depthtex0, topRightCorner, 0).x);
    float depth1 = near / (1.0 - texelFetch(depthtex0, bottomLeftCorner, 0).x);
    float depth2 = near / (1.0 - texelFetch(depthtex0, ivec2(topRightCorner.x, bottomLeftCorner.y), 0).x);
    float depth3 = near / (1.0 - texelFetch(depthtex0, ivec2(bottomLeftCorner.x, topRightCorner.y), 0).x);

    float sumDepth = depth0 + depth1 + depth2 + depth3;

    #if OUTLINES == 1
        // Calculate standard outlines
        return saturate(sumDepth - depthOrigin * 4.0);
    #else
        // Calculate dungeons outlines
        return saturate((sumDepth * 64.0 - depthOrigin * 256.0) / depthOrigin);
    #endif
}