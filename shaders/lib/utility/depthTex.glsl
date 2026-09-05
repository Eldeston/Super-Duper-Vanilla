// Not needed yet, too expensive for LODs
// #ifdef DISTANT_HORIZONS
//     float resizeDepthDH(in float oldDepth){
//         float newDepth = getViewDepth(dhProjectionInverse, oldDepth);
//         return min(1.0, getScreenDepth(gbufferProjection, newDepth));
//     }
// #endif

float getDepthTex(in ivec2 screenTexelCoord){
    #if defined DISTANT_HORIZONS
        float mainDepth = getDepth(depthtex0, screenTexelCoord, 0);

        return mainDepth == 1 ? texelFetch(dhDepthTex0, screenTexelCoord, 0).x : mainDepth;
    #elif defined VOXY
        float mainDepth = getDepth(depthtex0, screenTexelCoord, 0);

        return mainDepth == 1 ? texelFetch(vxDepthTexOpaque, screenTexelCoord, 0).x : mainDepth;
    #else
        return getDepth(depthtex0, screenTexelCoord, 0);
    #endif
}

float getDepthTex(in vec2 screenCoord){
    #if defined DISTANT_HORIZONS
        float mainDepth = getDepth(depthtex0, screenCoord, 0);

        return mainDepth == 1 ? textureLod(dhDepthTex0, screenCoord, 0).x : mainDepth;
    #elif defined VOXY
        float mainDepth = getDepth(depthtex0, screenCoord, 0);

        return mainDepth == 1 ? textureLod(vxDepthTexOpaque, screenCoord, 0).x : mainDepth;
    #else
        return getDepth(depthtex0, screenCoord, 0);
    #endif
}