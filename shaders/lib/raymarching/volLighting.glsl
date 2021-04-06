vec3 getGodRays(vec3 playerPos, vec2 glTexCoord){
	float dither = fract(texture2D(noisetex, glTexCoord * 0.0625, 1).x);
	playerPos *= 1.0 + dither * 0.3333;
	vec3 rayData = vec3(0.0);
	float densityMult = float(1 + isEyeInWater * 2);
	for(int x = 0; x < 8; x++){
		playerPos *= 0.765;
		vec3 shdPos = toShadow(playerPos).xyz;
		shdPos = distort(shdPos) * 0.5 + 0.5;
		float shd0 = shadow2D(shadowtex0, shdPos.xyz).x;
		float shd1 = shadow2D(shadowtex1, shdPos.xyz).x - shd0;
		vec3 rayCol = texture2D(shadowcolor0, shdPos.xy).rgb * shd1 * (1.0 - shd0) + shd0;
		rayData = mix(rayCol, rayData, exp2(length(playerPos) * -0.0078125 * densityMult));
	}
	return rayData * float(isEyeInWater + 1);
}