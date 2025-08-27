float getDepthTex(in ivec2 screenTexelCoord){
    #ifdef DISTANT_HORIZONS
        float mainDepth = getDepth(depthtex0, screenTexelCoord, 0);

        return mainDepth == 1 ? texelFetch(dhDepthTex0, screenTexelCoord, 0).x : mainDepth;
    #else
        return getDepth(depthtex0, screenTexelCoord, 0);
    #endif
}

float getDepthTex(in vec2 screenCoord){
    #ifdef DISTANT_HORIZONS
        float mainDepth = getDepth(depthtex0, screenCoord, 0);

        return mainDepth == 1 ? textureLod(dhDepthTex0, screenCoord, 0).x : mainDepth;
    #else
        return getDepth(depthtex0, screenCoord, 0);
    #endif
}