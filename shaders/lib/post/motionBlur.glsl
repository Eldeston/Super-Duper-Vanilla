vec3 motionBlur(vec3 currColor, vec2 currScreenPos, float dither){
    vec2 prevPosition = (currScreenPos - toPrevScreenPos(currScreenPos)) * 0.25 * MOTION_BLUR_STRENGTH;

    // Apply dithering
    currScreenPos += prevPosition * dither;
    
    for(int i = 0; i < 4; i++){
        currScreenPos += prevPosition;
        currColor += texture2D(gcolor, saturate(currScreenPos)).rgb;
    }

    return currColor * 0.2;
}