float getSSAO(vec3 viewPos, vec3 normal){
    #if ANTI_ALIASING >= 2
        vec3 dither = toRandPerFrame(getRand3(ivec2(gl_FragCoord.xy) & 255), frameTimeCounter);
    #else
        vec3 dither = getRand3(ivec2(gl_FragCoord.xy) & 255);
    #endif

    float occlusion = 0.0;

    for(int i = 0; i < 4; i++){
        // Iterate by adding stepsize
        dither += 0.25;

        // Add new offsets to origin
        vec3 samplePos = viewPos + (normal + fract(dither) - 0.5) * 0.5;
        // Sample new depth and linearize
        float sampleDepth = toView(texture2D(depthtex0, toScreen(samplePos).xy).x);

        // Check if the offset points are inside geometry or if the point is occluded
        occlusion += sampleDepth > samplePos.z ? smoothen(0.5 / abs(viewPos.z - sampleDepth)) : 0.0;
    }
    
    // Invert results and return
    return 1.0 - occlusion * 0.25;
}