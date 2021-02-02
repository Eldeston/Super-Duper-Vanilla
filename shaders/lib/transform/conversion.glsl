// Get cam space pos
vec4 getCamSpacePos(vec2 st, bool ortho){
	vec3 screenPos = vec3(st, getDepth(st));
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