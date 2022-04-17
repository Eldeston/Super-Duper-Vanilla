float getWaterHeightBilinear(vec2 uv){
    float pixSize = 1.0 / noiseTextureResolution;

    float a = fract(uv.x * noiseTextureResolution);

    float horizontal0 = mix(texture2D(noisetex, uv).z, texture2D(noisetex, uv + vec2(pixSize, 0)).z, a);
    float horizontal1 = mix(texture2D(noisetex, uv + vec2(0, pixSize)).z, texture2D(noisetex, uv + pixSize).z, a);
    
    return mix(horizontal0, horizontal1, fract(uv.y * noiseTextureResolution));
}

float getCellNoise(vec2 st){
    float animateTime = CURRENT_SPEED * newFrameTimeCounter * 0.0625;
    return (getWaterHeightBilinear(st + animateTime * 0.5) + getWaterHeightBilinear(animateTime - st)) * 0.5;
}

// Convert height map of water to a normal map
vec4 H2NWater(vec2 st){
    float waterPixel = WATER_BLUR_SIZE / noiseTextureResolution;
	vec2 waterUv = st / WATER_TILE_SIZE;

	float d0 = getCellNoise(waterUv);
	float d1 = getCellNoise(waterUv + vec2(waterPixel, 0));
	float d2 = getCellNoise(waterUv + vec2(0, waterPixel));
    
    return vec4(normalize(vec3(d0 - d1, d0 - d2, waterPixel * WATER_DEPTH_SIZE)), d0);
}