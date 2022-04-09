// --------------- Code Library ---------------- //
// Common utility functions goes here

#define PI 3.1415927
#define PI2 6.2831853
#define PI3 9.424778

#define ALPHA_THRESHOLD 0.005

// Saturate / clamp functions
float saturate(float x) { return clamp(x, 0.0, 1.0); }
vec2 saturate(vec2 x) { return clamp(x, vec2(0), vec2(1)); }
vec3 saturate(vec3 x) { return clamp(x, vec3(0), vec3(1)); }
vec4 saturate(vec4 x) { return clamp(x, vec4(0), vec4(1)); }

// Squared functions x^2
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

// Max functions
float max2(vec2 x) { return max(x.r, x.g); }
float maxC(vec3 x) { return max(x.r, max(x.g, x.b)); }
float maxC(vec4 x) { return max(x.r, max(x.g, max(x.b, x.a))); }

// Min functions
float min2(vec2 x) { return min(x.r, x.g); }
float minC(vec3 x) { return min(x.r, min(x.g, x.b)); }
float minC(vec4 x) { return min(x.r, min(x.g, min(x.b, x.a))); }

// Hermite interpolation
float hermiteMix(float a, float b, float x) { return saturate((x - a) / (b - a)); }
vec2 hermiteMix(float a, float b, vec2 x) { return saturate((x - a) / (b - a)); }
vec3 hermiteMix(float a, float b, vec3 x) { return saturate((x - a) / (b - a)); }
vec4 hermiteMix(float a, float b, vec4 x) { return saturate((x - a) / (b - a)); }
vec2 hermiteMix(vec2 a, vec2 b, vec2 x) { return saturate((x - a) / (b - a)); }
vec3 hermiteMix(vec3 a, vec3 b, vec3 x) { return saturate((x - a) / (b - a)); }
vec4 hermiteMix(vec4 a, vec4 b, vec4 x) { return saturate((x - a) / (b - a)); }

// Smoothstep functions
float smoothen(float x){
	x = saturate(x);
	return x * x * (3.0 - 2.0 * x);
	}

vec2 smoothen(vec2 x){
	x = saturate(x);
	return x * x * (3.0 - 2.0 * x);
	}

vec3 smoothen(vec3 x){
	x = saturate(x);
	return x * x * (3.0 - 2.0 * x);
	}

vec4 smoothen(vec4 x){
	x = saturate(x);
	return x * x * (3.0 - 2.0 * x);
	}

// Smootherstep functions
float smootherstep(float x){
	x = saturate(x);
	return x * x * x * (x * (x * 6.0 - 15.0) + 10.0);
	}

vec2 smootherstep(vec2 x){
	x = saturate(x);
	return x * x * x * (x * (x * 6.0 - 15.0) + 10.0);
	}

vec3 smootherstep(vec3 x){
	x = saturate(x);
	return x * x * x * (x * (x * 6.0 - 15.0) + 10.0);
	}

vec4 smootherstep(vec4 x){
	x = saturate(x);
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
	return saturate(0.5 * (1.0 - a) + col.rgb * a);
}

// Rotation function
mat2 rot2D(float x){
    return mat2(cos(x),-sin(x), sin(x),cos(x));
}

float edgeVisibility(vec2 screenPos){
    return smoothstep(0.0, 0.025, min2(screenPos * (1.0 - screenPos)));
}