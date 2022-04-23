float getSpectral(sampler2D mask, vec2 uv){
    vec2 pixSize = 1.0 / vec2(viewWidth, viewHeight);

    float totalDepth = texture2D(mask, uv + pixSize).z;
    totalDepth += texture2D(mask, uv - pixSize).z;
    totalDepth += texture2D(mask, uv + vec2(pixSize.x, -pixSize.y)).z;
    totalDepth += texture2D(mask, uv - vec2(pixSize.x, -pixSize.y)).z;

    // Calculate the differences of the offsetted depths...
    return abs(totalDepth * 0.25 - texture2D(mask, uv).z);
}