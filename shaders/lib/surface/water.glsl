float getWaterHeightBilinear(vec2 uv){
    float pixSize = 1.0 / noiseTextureResolution;

    float downLeft = texture2D(noisetex, uv).z;
    float downRight = texture2D(noisetex, uv + vec2(pixSize, 0)).z;

    float upRight = texture2D(noisetex, uv + vec2(0, pixSize)).z;
    float upLeft = texture2D(noisetex, uv + pixSize).z;

    float a = fract(uv.x * noiseTextureResolution);

    float horizontal0 = mix(downLeft, downRight, a);
    float horizontal1 = mix(upRight, upLeft, a);
    return mix(horizontal0, horizontal1, fract(uv.y * noiseTextureResolution));
}

float getCellNoise(vec2 st){
    float animateTime = CURRENT_SPEED * newFrameTimeCounter;
    float heightMap = getWaterHeightBilinear(st + animateTime * 0.025);
    return (heightMap + getWaterHeightBilinear(st - animateTime * 0.05)) * 0.5;
}

// Convert height map of water to a normal map
vec4 H2NWater(vec2 st){
    float waterPixel = WATER_BLUR_SIZE / noiseTextureResolution;
	vec2 waterUv = st / WATER_TILE_SIZE;

	float d0 = getCellNoise(waterUv);
	float d1 = d0 - getCellNoise(waterUv + vec2(waterPixel, 0));
	float d2 = d0 - getCellNoise(waterUv + vec2(0, waterPixel));
    
    return vec4(normalize(vec3(d1, d2, waterPixel * WATER_DEPTH_SIZE)), d0);
}