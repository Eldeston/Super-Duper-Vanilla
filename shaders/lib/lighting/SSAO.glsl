float getSSAO(vec3 viewPos, vec3 normal){
    #if ANTI_ALIASING >= 2
        vec3 dither = toRandPerFrame(getRand3(ivec2(gl_FragCoord.xy) & 255), frameTimeCounter);
    #else
        vec3 dither = getRand3(ivec2(gl_FragCoord.xy) & 255);
    #endif

    float occlusion = 0.0;

    // Instead of iterating by adding stepSize and using fract every time, we swizzle + one fract instead for pleasant results
    vec3 ditherSwizzle[4] = vec3[4](
        dither.xyz,
        dither.zxy,
        dither.yzx,
        fract(dither.zyx + GOLDEN_RATIO)
        );

    for(int i = 0; i < 4; i++){
        // Add new offsets to origin
        vec3 samplePos = viewPos + (normal + ditherSwizzle[i] - 0.5) * 0.5;
        // Sample new depth and linearize
        float sampleDepth = toView(texture2D(depthtex0, toScreen(samplePos).xy).x);

        // Check if the offset points are inside geometry or if the point is occluded
        if(sampleDepth > samplePos.z) occlusion += min(1.0 / (sampleDepth - viewPos.z), 1.0);
    }
    
    // Invert results and return
    return 1.0 - occlusion * 0.25;
}