#ifdef SHADOW_DISTORT
	//euclidian distance is defined as sqrt(a^2 + b^2 + ...)
	//this length function instead does cbrt(a^3 + b^3 + ...)
	//this results in smaller distances along the diagonal axes.
	float cubeLength(vec2 v){
		return pow(abs(v.x * v.x * v.x) + abs(v.y * v.y * v.y), 1.0 / 3.0);
	}
	
	float getDistortFactor(vec2 v){
		return cubeLength(v) + SHADOW_DISTORT_FACTOR;
	}
#else
	float getDistortFactor(vec2 v){
		return 1.0;
	}
#endif

vec3 distort(vec3 v, float factor) {
	return vec3(v.xy / factor, v.z * 0.5);
}

vec3 distort(vec3 v) {
	return distort(v, getDistortFactor(v.xy));
}