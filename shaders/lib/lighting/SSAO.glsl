float getSSAO(in vec3 screenPos, in vec3 viewNormal){
    #if ANTI_ALIASING >= 2
        vec3 dither = toRandPerFrame(getRand3(ivec2(gl_FragCoord.xy) & 255), frameTimeCounter);
    #else
        vec3 dither = getRand3(ivec2(gl_FragCoord.xy) & 255);
    #endif

    float occlusion = 0.25;

    // Instead of iterating by adding stepSize and using fract every time, we swizzle + one fract instead for pleasant and optimized results
    vec3 baseDither = (dither.xyz - 0.5) * 0.5;
	vec3 ditherSwizzle[4] = vec3[4](
		baseDither.xyz,
		baseDither.zxy,
		baseDither.yzx,
		(fract(dither.zyx + GOLDEN_RATIO) - 0.5) * 0.5
	);

    float depthOrigin = near / (1.0 - screenPos.z);
    // Pre calculate base position
    vec3 basePos = toView(screenPos) + viewNormal * 0.5;

    for(int i = 0; i < 4; i++){
        // Add new offsets to origin
        vec3 samplePos = toScreen(basePos + ditherSwizzle[i]);
        // Sample new depth and linearize
        float sampleDepth = textureLod(depthtex0, samplePos.xy, 0).x;

        // Check if the offset points are inside geometry or if the point is occluded
        if(samplePos.z > sampleDepth) occlusion -= 0.0625 / max(depthOrigin - near / (1.0 - sampleDepth), 1.0);
    }

    // Remap results and return
    return occlusion;
}