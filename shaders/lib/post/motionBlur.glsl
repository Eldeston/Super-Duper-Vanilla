vec3 motionBlur(in vec3 currColor, in float depth){
    ivec2 viewResolution = ivec2(viewWidth - 1, viewHeight - 1);
    vec2 prevPosition = (gl_FragCoord.xy - vec2(viewWidth, viewHeight) * getPrevScreenCoord(texCoord, depth)) * MOTION_BLUR_STRENGTH * 0.2;

    // Apply dithering
    float dither = IGN(gl_FragCoord.xy);
    vec2 currScreenPos = gl_FragCoord.xy + prevPosition * dither;
    
    for(uint i = 0u; i < 4u; i++){
        currScreenPos += prevPosition;
        currColor += texelFetch(colortex4, clamp(ivec2(currScreenPos), ivec2(0), viewResolution), 0).rgb;
    }

    return currColor * 0.2;
}