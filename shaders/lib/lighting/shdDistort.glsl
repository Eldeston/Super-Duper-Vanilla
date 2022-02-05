float getDistortFactor(vec2 v){
	return length(v) + 0.1;
}

vec3 distort(vec3 v, float factor) {
	return vec3(v.xy / factor, v.z * 0.25);
}

vec3 distort(vec3 v) {
	return distort(v, getDistortFactor(v.xy));
}