vec3 motionBlur(vec3 currColor, vec2 currScreenPos, float depth, float dither){
    vec2 prevPosition = (currScreenPos.xy - toPrevScreenPos(currScreenPos, depth)) * MOTION_BLUR_STRENGTH * 0.2;

    // Apply dithering
    currScreenPos += prevPosition * dither;
    
    for(int i = 0; i < 4; i++){
        currScreenPos += prevPosition;
        currColor += texture2DLod(gcolor, saturate(currScreenPos), 0).rgb;
    }

    return currColor * 0.2;
}