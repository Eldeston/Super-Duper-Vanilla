vec3 motionBlur(in vec3 currColor, in float depth, in float dither){
    vec2 prevPosition = (texCoord.xy - getPrevScreenCoord(texCoord, depth)) * MOTION_BLUR_STRENGTH * 0.2;
    if(dot(prevPosition, prevPosition) < 1e-7) return currColor;

    // Apply dithering
    vec2 currScreenPos = texCoord + prevPosition * dither;
    
    for(uint i = 0u; i < 4u; i++){
        currScreenPos += prevPosition;
        currColor += textureLod(colortex4, currScreenPos, 0).rgb;
    }

    return currColor * 0.2;
}