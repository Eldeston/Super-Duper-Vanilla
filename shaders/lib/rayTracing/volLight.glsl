vec3 getGodRays(vec3 feetPlayerPos, float worldPosY, float dither){
	#if defined NETHER || defined END
		return vec3(0);
	#else
		if(VOL_LIGHT_BRIGHTNESS == 0) return vec3(0);

		feetPlayerPos *= 1.0 + dither * 0.3333;

		vec3 rayData = vec3(0);
		float densityMult = float(1 + isEyeInWater * 2);
		for(int x = 0; x < 8; x++){
			feetPlayerPos *= 0.766;
			vec3 shdPos = toShadow(feetPlayerPos).xyz;
			shdPos = distort(shdPos) * 0.5 + 0.5;

			vec3 rayCol = getShdTex(shdPos);
			float fog = atmoFog(feetPlayerPos.y, worldPosY, length(feetPlayerPos), 0.08, 0.07);
			rayData = mix(rayData, rayCol, fog);
		}
		return rayData * float(isEyeInWater + 1) * VOL_LIGHT_BRIGHTNESS * (1.0 - newTwilight) * (1.0 - blindness * 0.5);
	#endif
}