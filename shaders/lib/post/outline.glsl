vec3 getOutline(sampler2D depthTex, vec3 color, vec2 st){
    float offSet = OUTLINE_PIX_SIZE / max(viewWidth, viewHeight);
    float depth0 = toView(texture2D(depthTex, st).x);
    float totalDepth = 0.0;

    totalDepth += toView(texture2D(depthTex, st - offSet).x);
    totalDepth += toView(texture2D(depthTex, st + offSet).x);

    totalDepth += toView(texture2D(depthTex, st - vec2(offSet, -offSet)).x);
    totalDepth += toView(texture2D(depthTex, st + vec2(offSet, -offSet)).x);

    totalDepth += toView(texture2D(depthTex, st - vec2(offSet, 0)).x);
    totalDepth += toView(texture2D(depthTex, st + vec2(offSet, 0)).x);

    totalDepth += toView(texture2D(depthTex, st - vec2(0, offSet)).x);
    totalDepth += toView(texture2D(depthTex, st + vec2(0, offSet)).x);

    // Calculate the differences of the offsetted depths...
    float dDepth = totalDepth - depth0 * 8.0;

    return color * (1.0 + saturate(dDepth) * (OUTLINE_BRIGHTNESS - 1.0));
}