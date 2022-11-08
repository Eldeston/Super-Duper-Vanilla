float getDistortFactor(in vec2 pos){
	return length(pos) + 0.1;
}

vec3 distort(in vec3 pos, in float factor){
	return vec3(pos.xy / factor, pos.z * 0.2);
}

vec3 distort(in vec3 pos){
	return distort(pos, getDistortFactor(pos.xy));
}