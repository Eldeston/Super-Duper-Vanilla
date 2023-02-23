vec3 toScreen(in vec3 pos){
	vec3 data = vec3(gbufferProjection[0].x, gbufferProjection[1].y, gbufferProjection[2].z) * pos;
	return (vec3(data.xy, data.z + gbufferProjection[3].z) / -pos.z) * 0.5 + 0.5;
}

vec2 toScreenCoord(in vec3 pos){
	vec2 data = vec2(gbufferProjection[0].x, gbufferProjection[1].y) * pos.xy;
	return (data.xy / -pos.z) * 0.5 + 0.5;
}

float toScreen(in float depth){
	return ((gbufferProjection[2].z * depth + gbufferProjection[3].z) / -depth) * 0.5 + 0.5;
}