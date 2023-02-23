vec3 motionBlur(in vec3 currColor, in float depth, in float dither){
    vec2 prevPosition = (texCoord.xy - toPrevScreenPos(texCoord, depth)) * MOTION_BLUR_STRENGTH * 0.2;

    // Apply dithering
    vec2 currScreenPos = texCoord + prevPosition * dither;
    
    for(int i = 0; i < 4; i++){
        currScreenPos += prevPosition;
        currColor += textureLod(gcolor, currScreenPos, 0).rgb;
    }

    return currColor * 0.2;
}