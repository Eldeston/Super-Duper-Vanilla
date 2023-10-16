float getOutline(in ivec2 iUv, in float depthOrigin){
    ivec2 topRightCorner = iUv - OUTLINE_PIXEL_SIZE;
    ivec2 bottomLeftCorner = iUv + OUTLINE_PIXEL_SIZE;

    // (1.0 - screenPos.z) / near
    // near / (1.0 - screenPos.z)

    #if OUTLINES == 1
        float depth0 = near / (1.0 - texelFetch(depthtex0, topRightCorner, 0).x);
        float depth1 = near / (1.0 - texelFetch(depthtex0, bottomLeftCorner, 0).x);
        float depth2 = near / (1.0 - texelFetch(depthtex0, ivec2(topRightCorner.x, bottomLeftCorner.y), 0).x);
        float depth3 = near / (1.0 - texelFetch(depthtex0, ivec2(bottomLeftCorner.x, topRightCorner.y), 0).x);

        float sumDepth = depth0 + depth1 + depth2 + depth3;

        // Calculate standard outlines
        return saturate(sumDepth - (near * 4.0) / (1.0 - depthOrigin));
    #else
        float depth0 = 64.0 / (1.0 - texelFetch(depthtex0, topRightCorner, 0).x);
        float depth1 = 64.0 / (1.0 - texelFetch(depthtex0, bottomLeftCorner, 0).x);
        float depth2 = 64.0 / (1.0 - texelFetch(depthtex0, ivec2(topRightCorner.x, bottomLeftCorner.y), 0).x);
        float depth3 = 64.0 / (1.0 - texelFetch(depthtex0, ivec2(bottomLeftCorner.x, topRightCorner.y), 0).x);

        float sumDepth = depth0 + depth1 + depth2 + depth3;

        // Calculate dungeons outlines
        return saturate((1.0 - depthOrigin) * sumDepth - 256.0);
    #endif
}