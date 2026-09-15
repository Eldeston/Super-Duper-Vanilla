// Not needed yet, too expensive for LODs
// #ifdef DISTANT_HORIZONS
//     float resizeDepthDH(in float oldDepth){
//         float newDepth = getViewDepth(dhProjectionInverse, oldDepth);
//         return min(1.0, getScreenDepth(gbufferProjection, newDepth));
//     }
// #endif

float getDepthTex(in ivec2 screenTexelCoord){
    float mainDepth = getDepth(depthtex0, screenTexelCoord, 0);

    #if defined DISTANT_HORIZONS
        if(mainDepth == 1) return getDepth(dhDepthTex0, screenTexelCoord, 0);
    #elif defined VOXY
        if(mainDepth == 1) return getDepth(vxDepthTexOpaque, screenTexelCoord, 0);
    #endif

    return mainDepth;
}

float getDepthTex(in vec2 screenCoord){
    float mainDepth = getDepth(depthtex0, screenCoord, 0);

    #if defined DISTANT_HORIZONS
        if(mainDepth == 1) return getDepth(dhDepthTex0, screenCoord, 0);
    #elif defined VOXY
        if(mainDepth == 1) return getDepth(vxDepthTexOpaque, screenCoord, 0);
    #endif

    return mainDepth;
}