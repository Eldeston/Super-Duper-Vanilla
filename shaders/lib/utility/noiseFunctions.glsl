// Default noise resolution
const int noiseTextureResolution = 256;

// Noise sample, r for blue noise, g for white noise, and b for cell noise
uniform sampler2D noisetex;

// Noise texture
vec4 getRandTex(vec2 st, int tile){
	return texture2D(noisetex, st * tile);
}

vec3 getRand3(vec2 st, int tile){
    st *= tile;
    return vec3(texture2D(noisetex, st).x, texture2D(noisetex, vec2(-st.x, st.y)).x, texture2D(noisetex, -st).x);
}

float toRandPerFrame(float rand){
    if(NOISE_SPEED == 0) return fract(rand * 4.0);
    return fract(rand * 4.0 + frameTimeCounter * NOISE_SPEED);
}

vec2 toRandPerFrame(vec2 rand){
    if(NOISE_SPEED == 0) return fract(rand * 4.0);
    return fract(rand * 4.0 + frameTimeCounter * NOISE_SPEED);
}

vec3 toRandPerFrame(vec3 rand){
    if(NOISE_SPEED == 0) return fract(rand * 4.0);
    return fract(rand * 4.0 + frameTimeCounter * NOISE_SPEED);
}

float getCellNoise(vec2 st){
    float d0 = tex2DBilinear(noisetex, st + frameTimeCounter * 0.0125, vec2(256)).z;
    float d1 = tex2DBilinear(noisetex, st * 4.0 - frameTimeCounter * 0.05, vec2(256)).z;
    #ifdef INVERSE
        return 1.0 - d0 * 0.875 + d1 * 0.125;
    #else
        return d0 * 0.875 + d1 * 0.125;
    #endif
}

// Convert height map of water to a normal map
vec4 H2NWater(vec2 st){
    float waterPixel = WATER_BLUR_SIZE / noiseTextureResolution;
	vec2 waterUv = st / WATER_TILE_SIZE;

	float d = getCellNoise(waterUv);
	float dx = (d - getCellNoise(waterUv + vec2(waterPixel, 0))) / waterPixel;
	float dy = (d - getCellNoise(waterUv + vec2(0, waterPixel))) / waterPixel;

    #ifdef INVERSE
        d = 1.0 - d;
    #endif
    
    return vec4(normalize(vec3(dx, dy, WATER_DEPTH_SIZE)), d);
}