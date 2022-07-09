// --------------- Code Library ---------------- //
// Common utility functions goes here

#define GAMMA 2.2
#define RCPGAMMA 0.45454545

#define GOLDEN_RATIO 1.61803399
#define PI 3.14159265
#define PI2 6.28318531

#define ALPHA_THRESHOLD 0.005

// Saturate/clamp functions
float saturate(float x) { return clamp(x, 0.0, 1.0); }
vec2 saturate(vec2 x) { return clamp(x, vec2(0), vec2(1)); }
vec3 saturate(vec3 x) { return clamp(x, vec3(0), vec3(1)); }
vec4 saturate(vec4 x) { return clamp(x, vec4(0), vec4(1)); }

// Squared functions x ^ 2
float squared(float x) { return x * x; }
vec2 squared(vec2 x) { return x * x; }
vec3 squared(vec3 x) { return x * x; }
vec4 squared(vec4 x) { return x * x; }

// Cubed functions x^3
float cubed(float x) { return x * x * x; }
vec2 cubed(vec2 x) { return x * x * x; }
vec3 cubed(vec3 x) { return x * x * x; }
vec4 cubed(vec4 x) { return x * x * x; }

float lengthSquared(vec2 x){ return dot(x, x); }
float lengthSquared(vec3 x){ return dot(x, x); }

// Min functions
float minOf(vec2 x) { return min(x.x, x.y); }
float minOf(vec3 x) { return min(x.x, min(x.y, x.z)); }
float minOf(vec4 x) { return min(min(x.x, x.y), min(x.z, x.w)); }

// Max functions
float maxOf(vec2 x) { return max(x.x, x.y); }
float maxOf(vec3 x) { return max(x.x, max(x.y, x.z)); }
float maxOf(vec4 x) { return max(max(x.x, x.y), max(x.z, x.w)); }

float sumOf(vec2 x) { return x.x + x.y; }
float sumOf(vec3 x) { return x.x + x.y + x.z; }
float sumOf(vec4 x) { return x.x + x.y + x.z + x.w; }

// Hermite interpolation
float hermiteMix(float a, float b, float x) { return (x - a) / (b - a); }
vec2 hermiteMix(float a, float b, vec2 x) { return (x - a) / (b - a); }
vec3 hermiteMix(float a, float b, vec3 x) { return (x - a) / (b - a); }
vec4 hermiteMix(float a, float b, vec4 x) { return (x - a) / (b - a); }
vec2 hermiteMix(vec2 a, vec2 b, vec2 x) { return (x - a) / (b - a); }
vec3 hermiteMix(vec3 a, vec3 b, vec3 x) { return (x - a) / (b - a); }
vec4 hermiteMix(vec4 a, vec4 b, vec4 x) { return (x - a) / (b - a); }

float fastSqrt(float x){ return x * (2.0 - x); }
vec2 fastSqrt(vec2 x){ return x * (2.0 - x); }
vec3 fastSqrt(vec3 x){ return x * (2.0 - x); }
vec4 fastSqrt(vec4 x){ return x * (2.0 - x); }

// Smoothstep functions
float smoothen(float x){
	return x * x * (3.0 - 2.0 * x);
}

vec2 smoothen(vec2 x){
	return x * x * (3.0 - 2.0 * x);
}

vec3 smoothen(vec3 x){
	return x * x * (3.0 - 2.0 * x);
}

vec4 smoothen(vec4 x){
	return x * x * (3.0 - 2.0 * x);
}

// Smootherstep functions
float smootherstep(float x){
	return x * x * x * (x * (x * 6.0 - 15.0) + 10.0);
	}

vec2 smootherstep(vec2 x){
	return x * x * x * (x * (x * 6.0 - 15.0) + 10.0);
}

vec3 smootherstep(vec3 x){
	return x * x * x * (x * (x * 6.0 - 15.0) + 10.0);
}

vec4 smootherstep(vec4 x){
	return x * x * x * (x * (x * 6.0 - 15.0) + 10.0);
}

float getLuminance(vec3 col){
	return col.r * 0.2125 + col.g * 0.7154 + col.b * 0.0721;
}

// Saturation function
vec3 toneSaturation(vec3 col, float a){
	// Algorithm from Chapter 16 of OpenGL Shading Language
	return getLuminance(col) * (1.0 - a) + col * a;
}

// Contrast function
vec3 toneContrast(vec3 col, float a){
	return saturate((col.rgb - 0.5) * a + 0.5);
}

// By Jessie#7257
vec3 generateUnitVector(vec2 hash){
    hash.x *= PI2; hash.y = hash.y * 2.0 - 1.0;
    return vec3(vec2(sin(hash.x), cos(hash.x)) * sqrt(1.0 - hash.y * hash.y), hash.y);
}

// Rotation function
mat2 rot2D(float x){
    return mat2(cos(x),-sin(x), sin(x),cos(x));
}