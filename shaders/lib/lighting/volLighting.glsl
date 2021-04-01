vec3 getGodRays(vec2 st, vec2 glTexCoord){
	float dither = fract(getRandTex(glTexCoord * 0.0625, 1).x + frameTimeCounter);
	vec4 pos = vec4(toScreenSpacePos(st), 1.0);
	pos.xyz = mat3(gbufferModelViewInverse) * toLocal(pos.xyz);
	// Dither to decrease banding
	pos.xyz *= 1.0 + dither * 0.3333;
	// pos.xyz += normalize(pos.xyz) * dither * 0.005;
	vec3 rayData = vec3(0.0);
	for(int x = 0; x < 8; x++){
		pos.xyz *= 0.75;
		vec3 shdPos = toShadow(pos.xyz).xyz;
		shdPos = distort(shdPos) * 0.5 + 0.5;
		float shd0 = shadow2D(shadowtex0, shdPos.xyz).x;
		float shd1 = shadow2D(shadowtex1, shdPos.xyz).x - shd0;
		vec3 rayCol = texture2D(shadowcolor0, shdPos.xy).rgb * shd1 * (1.0 - shd0) + shd0;
		rayData = mix(rayCol, rayData, exp2(length(pos.xyz) * -0.0625));
	}
	return rayData;
}