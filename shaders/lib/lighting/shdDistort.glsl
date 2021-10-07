#ifdef SHADOW_DISTORT
	float getDistortFactor(vec2 v){
		return length(v) + SHADOW_DISTORT_FACTOR;
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