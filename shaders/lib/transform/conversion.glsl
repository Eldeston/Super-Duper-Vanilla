// Get screen space pos
vec3 getScreenSpacePos(vec2 st){
	return vec3(st, texture2D(depthtex0, st).r);
}

// Get cam space pos
vec4 getCamSpacePos(vec2 st, bool ortho){
	vec3 screenPos = getScreenSpacePos(st);
	vec4 clipPos = vec4(screenPos * 2.0 - 1.0, 1.0);
	vec4 tmp = gbufferProjectionInverse * clipPos;
	if(ortho) return tmp; // Return value immediately, no division required
	else return vec4(tmp.xyz / tmp.w, tmp.w); // Return with perspective division
}

// Get eye player pos
vec4 getEyePlayerPos(vec2 st, bool ortho){
	return gbufferModelViewInverse * getCamSpacePos(st, ortho);
}

vec4 getShdPos(vec2 st, bool ortho){
	vec4 shdPos = shadowProjection * (shadowModelView * getEyePlayerPos(st, ortho));
	shdPos.xyz /= shdPos.w;
	float distortFactor = getDistortFactor(shdPos.xy);

	return vec4(shdPos.xyz, distortFactor); // Output final result with distort factor
}

/* ----- Converters ----- */

vec3 toScreen(vec3 pos){
	vec3 data = vec3(gbufferProjection[0].x, gbufferProjection[1].y, gbufferProjection[2].z) * pos;
	data += gbufferProjection[3].xyz;
	return (data.xyz / -pos.z) * 0.5 + 0.5;
}

vec3 toLocal(vec3 pos){
	vec4 result = vec4(pos * 2.0 - 1.0, 1.0);
	result = gbufferProjectionInverse * result;
	return result.xyz / result.w;
}