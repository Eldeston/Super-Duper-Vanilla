// --------------- Code Library ---------------- //
// Common utility functions goes here

#define PI 3.14159265
#define TAU 6.28318531
#define GOLDEN_RATIO 1.61803399

#define ALPHA_THRESHOLD 0.005

// Saturate/clamp functions
float saturate(in float x){ return clamp(x, 0.0, 1.0); }
vec2 saturate(in vec2 x){ return clamp(x, vec2(0), vec2(1)); }
vec3 saturate(in vec3 x){ return clamp(x, vec3(0), vec3(1)); }
vec4 saturate(in vec4 x){ return clamp(x, vec4(0), vec4(1)); }

// Squared functions x ^ 2
float squared(in float x){ return x * x; }
vec2 squared(in vec2 x){ return x * x; }
vec3 squared(in vec3 x){ return x * x; }
vec4 squared(in vec4 x){ return x * x; }

// Cubed functions x^3
float cubed(in float x){ return x * x * x; }
vec2 cubed(in vec2 x){ return x * x * x; }
vec3 cubed(in vec3 x){ return x * x * x; }
vec4 cubed(in vec4 x){ return x * x * x; }

// Length squared
float lengthSquared(in vec2 x){ return dot(x, x); }
float lengthSquared(in vec3 x){ return dot(x, x); }
float lengthSquared(in vec4 x){ return dot(x, x); }

// Faster normalize using inversesqrt()
vec2 fastNormalize(in vec2 x){ return x * inversesqrt(lengthSquared(x)); }
vec3 fastNormalize(in vec3 x){ return x * inversesqrt(lengthSquared(x)); }
vec4 fastNormalize(in vec4 x){ return x * inversesqrt(lengthSquared(x)); }

// Min functions
float minOf(in vec2 x){ return min(x.x, x.y); }
float minOf(in vec3 x){ return min(x.x, min(x.y, x.z)); }
float minOf(in vec4 x){ return min(min(x.x, x.y), min(x.z, x.w)); }

// Max functions
float maxOf(in vec2 x){ return max(x.x, x.y); }
float maxOf(in vec3 x){ return max(x.x, max(x.y, x.z)); }
float maxOf(in vec4 x){ return max(max(x.x, x.y), max(x.z, x.w)); }

// Sum functions
float sumOf(in vec2 x){ return x.x + x.y; }
float sumOf(in vec3 x){ return x.x + x.y + x.z; }
float sumOf(in vec4 x){ return x.x + x.y + x.z + x.w; }

// Linear interpolation functions
float lerp(float a, float b, float c, float d){
	if(d < 1) return mix(a, b, d);
    return mix(b, c, d - 1.0);
}

vec3 lerp(vec3 a, vec3 b, vec3 c, float d){
	if(d < 1) return mix(a, b, d);
    return mix(b, c, d - 1.0);
}

// Hermite interpolation
float hermiteMix(in float a, in float b, in float x){ return (x - a) / (b - a); }
vec2 hermiteMix(in float a, in float b, in vec2 x){ return (x - a) / (b - a); }
vec3 hermiteMix(in float a, in float b, in vec3 x){ return (x - a) / (b - a); }
vec4 hermiteMix(in float a, in float b, in vec4 x){ return (x - a) / (b - a); }
vec2 hermiteMix(in vec2 a, in vec2 b, in vec2 x){ return (x - a) / (b - a); }
vec3 hermiteMix(in vec3 a, in vec3 b, in vec3 x){ return (x - a) / (b - a); }
vec4 hermiteMix(in vec4 a, in vec4 b, in vec4 x){ return (x - a) / (b - a); }

// Fast approximate sqrt for 0-1 range
float fastSqrt(in float x){ return x * (2.0 - x); }
vec2 fastSqrt(in vec2 x){ return x * (2.0 - x); }
vec3 fastSqrt(in vec3 x){ return x * (2.0 - x); }
vec4 fastSqrt(in vec4 x){ return x * (2.0 - x); }

// Smoothstep functions
float smoothen(in float x){ return x * x * (3.0 - 2.0 * x); }
vec2 smoothen(in vec2 x){ return x * x * (3.0 - 2.0 * x); }
vec3 smoothen(in vec3 x){ return x * x * (3.0 - 2.0 * x); }
vec4 smoothen(in vec4 x){ return x * x * (3.0 - 2.0 * x); }

// Smootherstep functions
float smootherstep(in float x){ return x * x * x * (x * (x * 6.0 - 15.0) + 10.0); }
vec2 smootherstep(in vec2 x){ return x * x * x * (x * (x * 6.0 - 15.0) + 10.0); }
vec3 smootherstep(in vec3 x){ return x * x * x * (x * (x * 6.0 - 15.0) + 10.0); }
vec4 smootherstep(in vec4 x){ return x * x * x * (x * (x * 6.0 - 15.0) + 10.0); }

// By Jessie#7257
vec3 generateUnitVector(in vec2 hash){
    hash.x *= TAU; hash.y = hash.y * 2.0 - 1.0;
    return vec3(vec2(sin(hash.x), cos(hash.x)) * sqrt(1.0 - hash.y * hash.y), hash.y);
}

vec3 generateCosineVector(in vec3 vector, in vec3 noiseUnitVector){
	vec3 vectorDir = fastNormalize(vector + noiseUnitVector);
	return dot(vectorDir, vector) < 0 ? -vectorDir : vectorDir;
}

// Rotation function
mat2 rot2D(in float x){
	float cosX = cos(x);
  	float sinX = sin(x);
	return mat2(cosX, -sinX, sinX, cosX);
}

// SRGB to linear
float toLinear(in float x){ return ((2.10545 + x) * (0.0231872 + x)) * x * 0.315206; }
vec3 toLinear(in vec3 x){ return ((2.10545 + x) * (0.0231872 + x)) * x * 0.315206; }

// Linear to SRGB
float toSRGB(in float x){ return (inversesqrt(x) - 0.126893) * x * 1.14374; }
vec3 toSRGB(in vec3 x){ return (inversesqrt(x) - 0.126893) * x * 1.14374; }

/*
// SRGB to linear
float toLinear(in float x){ return pow(x, vec3(2.2)); }
vec3 toLinear(in vec3 x){ return pow(x, 2.2); }

// Linear to sRGB
float toSRGB(in float x){ return pow(x, vec3(1.0 / 2.2)); }
vec3 toSRGB(in vec3 x){ return pow(x, 1.0 / 2.2); }

// SRGB to linear
float toLinear(in float x){ return ((2.10545 + x) * (0.0231872 + x)) * x * 0.315206; }
vec3 toLinear(in vec3 x){ return ((2.10545 + x) * (0.0231872 + x)) * x * 0.315206; }

// Linear to SRGB
float toSRGB(in float x){ return (inversesqrt(x) - 0.126893) * x * 1.14374; }
vec3 toSRGB(in vec3 x){ return (inversesqrt(x) - 0.126893) * x * 1.14374; }
*/