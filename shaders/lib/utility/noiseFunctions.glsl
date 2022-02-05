// Default noise resolution
const int noiseTextureResolution = 256;

// Noise sample, r for blue noise, g for white noise, and b for cell noise
uniform sampler2D noisetex;

// Noise texture
vec4 getRandTex(vec2 st){
	return texture2D(noisetex, st);
}

float getRand1(vec2 st){
    return fract(texture2D(noisetex, st).x * 4.0);
}

vec2 getRand2(vec2 st){
    return fract(vec2(texture2D(noisetex, st).x, texture2D(noisetex, vec2(-st.x, st.y)).x) * 4.0);
}

vec3 getRand3(vec2 st){
    return fract(vec3(texture2D(noisetex, st).x, texture2D(noisetex, vec2(-st.x, st.y)).x, texture2D(noisetex, -st).x) * 4.0);
}

float toRandPerFrame(float rand, float time){
    return fract(rand + time * NOISE_SPEED);
}

vec2 toRandPerFrame(vec2 rand, float time){
    return fract(rand + time * NOISE_SPEED);
}

vec3 toRandPerFrame(vec3 rand, float time){
    return fract(rand + time * NOISE_SPEED);
}