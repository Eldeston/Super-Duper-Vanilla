float getCellNoise(in vec2 uv){
    const float currentSpeed = CURRENT_SPEED * 0.0625;
    float animateTime = newFrameTimeCounter * currentSpeed;
    return textureLod(noisetex, uv + animateTime, 0).z + textureLod(noisetex, animateTime - uv, 0).z;
}

// Convert height map of water to a normal map
vec4 H2NWater(in vec2 uv){
    const float waterPixel = WATER_BLUR_SIZE * 0.00390625;
    const float waterDepth = WATER_BLUR_SIZE * WATER_DEPTH_SIZE;

	float d0 = getCellNoise(uv);
	float d1 = getCellNoise(vec2(uv.x + waterPixel, uv.y));
	float d2 = getCellNoise(vec2(uv.x, uv.y + waterPixel));
    
    return vec4(fastNormalize(vec3(d0 - d1, d0 - d2, waterDepth)), d0);
}