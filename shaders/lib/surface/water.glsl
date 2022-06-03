float getCellNoise(vec2 uv){
    float animateTime = CURRENT_SPEED * newFrameTimeCounter * 0.05;
    return (texture2D(noisetex, uv + animateTime).z + texture2D(noisetex, animateTime - uv).z) * 0.5;
}

// Convert height map of water to a normal map
vec4 H2NWater(vec2 uv){
    float waterPixel = WATER_BLUR_SIZE * 0.00390625;
	vec2 waterUv = uv / WATER_TILE_SIZE;

	float d0 = getCellNoise(waterUv);
	float d1 = getCellNoise(waterUv + vec2(waterPixel, 0));
	float d2 = getCellNoise(waterUv + vec2(0, waterPixel));
    
    return vec4(normalize(vec3(d0 - d1, d0 - d2, waterPixel * WATER_DEPTH_SIZE)), d0);
}