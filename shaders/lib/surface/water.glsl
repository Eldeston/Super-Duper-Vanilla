float getCellNoise(in vec2 uv, in float animateTime){
    return textureLod(noisetex, uv + animateTime, 0).z + textureLod(noisetex, animateTime - uv, 0).z;
}

float getCellNoise(in vec2 uv){
    const float currentSpeed = CURRENT_SPEED * 0.0625;
    float animateTime = fragmentFrameTime * currentSpeed;
    return getCellNoise(uv, animateTime);
}

// Convert height map of water to a normal map
vec4 H2NWater(in vec2 uv, in float stormWindFactor){
    float currentSpeed = CURRENT_SPEED * 0.0625 * (1.0 + stormWindFactor * 1.6);
    float waterPixel = WATER_BLUR_SIZE * 0.00390625;
    float waterDepth = WATER_BLUR_SIZE * WATER_DEPTH_SIZE * (1.0 + stormWindFactor * 0.6);

    float animateTime = fragmentFrameTime * currentSpeed;

	float d0 = getCellNoise(uv, animateTime);
	float d1 = getCellNoise(vec2(uv.x + waterPixel, uv.y), animateTime);
	float d2 = getCellNoise(vec2(uv.x, uv.y + waterPixel), animateTime);
    
    return vec4(d0 - d1, d0 - d2, waterDepth, d0);
}

vec4 H2NWater(in vec2 uv){
    return H2NWater(uv, 0.0);
}