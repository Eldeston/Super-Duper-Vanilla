float getCellNoise(vec2 st){
    float animateTime = CURRENT_SPEED * frameTimeCounter;
    float d0 = texPix2DBilinear(noisetex, st + animateTime * 0.025, vec2(noiseTextureResolution)).z;
    float d1 = texPix2DBilinear(noisetex, st - animateTime * 0.05, vec2(noiseTextureResolution)).z;

    return (d0 + d1) * 0.5;
}

// Convert height map of water to a normal map
vec4 H2NWater(vec2 st){
    float waterPixel = WATER_BLUR_SIZE / noiseTextureResolution;
	vec2 waterUv = st / WATER_TILE_SIZE;

	float d = getCellNoise(waterUv);
	float dx = (d - getCellNoise(waterUv + vec2(waterPixel, 0))) / waterPixel;
	float dy = (d - getCellNoise(waterUv + vec2(0, waterPixel))) / waterPixel;
    
    return vec4(normalize(vec3(dx, dy, WATER_DEPTH_SIZE)), d);
}