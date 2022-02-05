vec3 toScreen(vec3 pos){
	vec3 data = vec3(gbufferProjection[0].x, gbufferProjection[1].y, gbufferProjection[2].z) * pos + gbufferProjection[3].xyz;
	return (data.xyz / -pos.z) * 0.5 + 0.5;
}

float toScreen(float depth){
	return ((gbufferProjection[2].z * depth + gbufferProjection[3].z) / -depth) * 0.5 + 0.5;
}

// Full screen position
vec3 toScreenSpacePos(vec2 st, sampler2D depthTex){
	return vec3(st, texture2D(depthTex, st).x);
}