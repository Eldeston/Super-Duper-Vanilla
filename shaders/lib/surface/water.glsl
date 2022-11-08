float getCellNoise(in vec2 uv){
    float animateTime = CURRENT_SPEED * newFrameTimeCounter * 0.05;
    return (texture2DLod(noisetex, uv + animateTime, 0).z + texture2DLod(noisetex, animateTime - uv, 0).z) * 0.5;
}

// Convert height map of water to a normal map
vec4 H2NWater(in vec2 uv){
    float waterPixel = WATER_BLUR_SIZE * 0.00390625;

	float d0 = getCellNoise(uv);
	float d1 = getCellNoise(vec2(uv.x + waterPixel, uv.y));
	float d2 = getCellNoise(vec2(uv.x, uv.y + waterPixel));
    
    return vec4(normalize(vec3(d0 - d1, d0 - d2, waterPixel * WATER_DEPTH_SIZE)), d0);
}