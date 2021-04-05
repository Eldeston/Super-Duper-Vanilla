vec3 getGodRays(vec2 st, vec2 glTexCoord){
	float dither = fract(texture2D(noisetex, glTexCoord * 0.0625, 1).x);
	vec4 pos = vec4(toScreenSpacePos(st), 1.0);
	pos.xyz = mat3(gbufferModelViewInverse) * toView(pos.xyz);
	pos.xyz *= 1.0 + dither * 0.3333;
	vec3 rayData = vec3(0.0);
	for(int x = 0; x < 8; x++){
		pos.xyz *= 0.76;
		vec3 shdPos = toShadow(pos.xyz).xyz;
		shdPos = distort(shdPos) * 0.5 + 0.5;
		float shd0 = shadow2D(shadowtex0, shdPos.xyz).x;
		float shd1 = shadow2D(shadowtex1, shdPos.xyz).x - shd0;
		vec3 rayCol = texture2D(shadowcolor0, shdPos.xy).rgb * shd1 * (1.0 - shd0) + shd0;
		rayData = mix(rayCol, rayData, exp2(length(pos.xyz) * -0.0078125));
	}
	return min(rayData * 3.2, vec3(1.0));
}