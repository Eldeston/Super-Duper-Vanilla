vec3 motionBlur(in vec3 currColor, in float depth, in float dither){
    float counter = 0.0;
    vec2 doublePixel = 2.0 / vec2(viewWidth, viewHeight);

    vec2 prevPosition = texCoord - getPrevScreenCoord(texCoord, depth);
    vec2 velocity = prevPosition / (1.0 + length(prevPosition)) * MOTION_BLUR_STRENGTH * 0.02;

    // Apply dithering
    vec2 currScreenPos = texCoord - velocity * (3.5 + dither);

    for(; counter < 9; counter++, currScreenPos += velocity){
        currScreenPos = clamp(currScreenPos, doublePixel, 1.0 - doublePixel);
        currColor += textureLod(gcolor, currScreenPos, 0).rgb;
    }

    return currColor /= counter;
}