// Default noise resolution
const int noiseTextureResolution = 256;

// Noise sample, r for blue noise, g for white noise, and b for cell noise
uniform sampler2D noisetex;

// Noise texture
vec4 getRandTex(vec2 st, int tile){
	return texture2D(noisetex, st * tile);
}

float getRand1(vec2 st, int tile){
    return fract(texture2D(noisetex, st * tile).x * 4.0);
}

vec2 getRand2(vec2 st, int tile){
    st *= tile;
    return fract(vec2(texture2D(noisetex, st).x, texture2D(noisetex, vec2(-st.x, st.y)).x) * 4.0);
}

vec3 getRand3(vec2 st, int tile){
    st *= tile;
    return fract(vec3(texture2D(noisetex, st).x, texture2D(noisetex, vec2(-st.x, st.y)).x, texture2D(noisetex, -st).x) * 4.0);
}

float toRandPerFrame(float rand){
    if(NOISE_SPEED == 0) return rand;
    return fract(rand + frameTimeCounter * NOISE_SPEED);
}

vec2 toRandPerFrame(vec2 rand){
    if(NOISE_SPEED == 0) return rand;
    return fract(rand + frameTimeCounter * NOISE_SPEED);
}

vec3 toRandPerFrame(vec3 rand){
    if(NOISE_SPEED == 0) return rand;
    return fract(rand + frameTimeCounter * NOISE_SPEED);
}

float getCellNoise(vec2 st){
    float animateTime = ANIMATION_SPEED * frameTimeCounter;
    float d0 = texPix2DBilinear(noisetex, st + animateTime * 0.02, vec2(256)).z;
    float d1 = texPix2DBilinear(noisetex, st * 4.0 - animateTime * 0.08, vec2(256)).z;

    return 1.0 - d0 * 0.9 + d1 * 0.1;
}

float getCellNoise2(vec2 st){
    float animateTime = ANIMATION_SPEED * frameTimeCounter;
    float d0 = texture2D(noisetex, st + animateTime * 0.032).z;
    float d1 = texPix2DBilinear(noisetex, st / 64.0 - animateTime * 0.001, vec2(256)).y;

    return (d0 + d1) * 0.5;
}

// Convert height map of water to a normal map
vec4 H2NWater(vec2 st){
    float waterPixel = WATER_BLUR_SIZE / noiseTextureResolution;
	vec2 waterUv = st / WATER_TILE_SIZE;

	float d = getCellNoise(waterUv);
	float dx = (d - getCellNoise(waterUv + vec2(waterPixel, 0))) / waterPixel;
	float dy = (d - getCellNoise(waterUv + vec2(0, waterPixel))) / waterPixel;
    
    return vec4(normalize(vec3(dx, dy, WATER_DEPTH_SIZE)), 1.0 - d);
}