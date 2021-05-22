vec3 getGodRays(vec3 feetPlayerPos, float worldPosY, float dither){
	#if defined NETHER || defined END
		return vec3(0);
	#endif
	feetPlayerPos *= 1.0 + dither * 0.3333;

	vec3 rayData = vec3(0.0);
	float densityMult = float(1 + isEyeInWater * 2);
	for(int x = 0; x < 8; x++){
		feetPlayerPos *= 0.766;

		vec3 shdPos = toShadow(feetPlayerPos).xyz;
		shdPos = distort(shdPos) * 0.5 + 0.5;
		float shd0 = shadow2D(shadowtex0, shdPos.xyz).x;
		float shd1 = shadow2D(shadowtex1, shdPos.xyz).x - shd0;
		vec3 rayCol = texture2D(shadowcolor0, shdPos.xy).rgb * shd1 * (1.0 - shd0) + shd0;
		// float fog = exp2(length(feetPlayerPos) * -0.0078125 * densityMult);
		float fog = atmoFog(feetPlayerPos.y, worldPosY, length(feetPlayerPos), 0.08, 0.07);
		rayData = mix(rayData, rayCol, fog);
	}
	return rayData * float(isEyeInWater + 1) * VOL_LIGHT_BRIGHTNESS * (1.0 - newTwilight);
}