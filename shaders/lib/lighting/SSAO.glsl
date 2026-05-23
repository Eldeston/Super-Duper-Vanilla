float getSSAO(in vec3 screenPos, in vec3 viewNormal){
    #if ANTI_ALIASING >= 2
        vec3 dither = fract(getRng3(ivec2(gl_FragCoord.xy) & 255) + frameFract);
    #else
        vec3 dither = getRng3(ivec2(gl_FragCoord.xy) & 255);
    #endif

    float occlusion = 0.25;

    // Instead of iterating by adding stepSize and using fract every time, we swizzle + one fract instead for pleasant and optimized results
    vec3 baseDither = dither.xyz * 0.5 - 0.25;
	vec3 ditherSwizzle[3] = vec3[3](
		baseDither.xyz,
		baseDither.zxy,
		baseDither.yzx
	);

    float depthOrigin = near / (1.0 - screenPos.z);

    // Pre calculate base position
    vec3 basePos = getViewPos(gbufferProjectionInverse, screenPos) + viewNormal * 0.5;

    for(uint i = 0u; i < 3u; i++){
        // Add new offsets to origin
        vec3 samplePos = getScreenPos(gbufferProjection, basePos + ditherSwizzle[i]);
        // Sample new depth and linearize
        float sampleDepth = textureLod(depthtex0, samplePos.xy, 0).x;

        // Check if the offset points are inside geometry or if the point is occluded
        if(samplePos.z > sampleDepth) occlusion -= 0.08333 / max(depthOrigin - near / (1.0 - sampleDepth), 1.0);
    }

    // Remap results and return
    return occlusion;
}