vec3 toScreen(in vec3 pos){
	vec3 data = vec3(gbufferProjection[0].x, gbufferProjection[1].y, gbufferProjection[2].z) * pos + gbufferProjection[3].xyz;
	return (data.xyz / -pos.z) * 0.5 + 0.5;
}

float toScreen(in float depth){
	return ((gbufferProjection[2].z * depth + gbufferProjection[3].z) / -depth) * 0.5 + 0.5;
}

vec2 toScreenCoord(in vec3 pos){
	vec2 data = vec2(gbufferProjection[0].x, gbufferProjection[1].y) * pos.xy + gbufferProjection[3].xy;
	return (data.xy / -pos.z) * 0.5 + 0.5;
}