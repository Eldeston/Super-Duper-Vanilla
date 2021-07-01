vec3 getGodRays(vec3 feetPlayerPos, float worldPosY, float dither){
	#if defined NETHER || defined END
		return vec3(0);
	#else
		float underWaterMult = float(isEyeInWater + 1);
		float volMult = VOL_LIGHT_BRIGHTNESS * (1.0 - newTwilight) * (1.0 - blindness * 0.6) * eyeBrightFact;
		#ifndef VOL_LIGHT
			return vec3(atmoFog(feetPlayerPos.y, worldPosY, length(feetPlayerPos), 0.08 * underWaterMult, 0.07 * underWaterMult) * volMult);
		#else
			if(VOL_LIGHT_BRIGHTNESS == 0) return vec3(0);
			feetPlayerPos *= 1.0 + dither * 0.3333;

			vec3 rayData = vec3(0);
			for(int x = 0; x < 8; x++){
				feetPlayerPos *= 0.766;
				vec3 shdPos = toShadow(feetPlayerPos).xyz;
				shdPos = distort(shdPos) * 0.5 + 0.5;

				vec3 rayCol = getShdTex(shdPos);
				float fog = atmoFog(feetPlayerPos.y, worldPosY, length(feetPlayerPos), 0.08 * underWaterMult, 0.07 * underWaterMult);
				rayData = mix(rayData, rayCol, fog);
			}
			return rayData * volMult;
		#endif
	#endif
}