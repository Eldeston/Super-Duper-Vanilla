vec3 getGodRays(vec3 feetPlayerPos, float worldPosY, float dither){
	#if defined NETHER || defined END
		return vec3(0);
	#else
		float c = HEIGHT_FOG_DENSITY * rainMult * underWaterMult * 1.44; float b = FOG_DENSITY * rainMult * underWaterMult * 1.44;

		float volMult = VOL_LIGHT_BRIGHTNESS * (1.0 - newTwilight) * (1.0 - blindness * 0.6) * (0.25 * (1.0 - eyeBrightFact) + eyeBrightFact) * min(1.0, FOG_OPACITY * 1.25 + rainMult * 0.1);

		#ifndef VOL_LIGHT
			return (atmoFog(feetPlayerPos.y, worldPosY, length(feetPlayerPos), c, b) * volMult) * lightCol;
		#else
			if(VOL_LIGHT_BRIGHTNESS == 0) return vec3(0);
			feetPlayerPos *= 1.0 + dither * 0.3333;

			vec3 rayData = vec3(0);
			for(int x = 0; x < 8; x++){
				feetPlayerPos *= 0.766;
				vec3 shdPos = toShadow(feetPlayerPos).xyz;
				shdPos = distort(shdPos) * 0.5 + 0.5;

				vec3 rayCol = getShdTex(shdPos);
				float fog = atmoFog(feetPlayerPos.y, worldPosY, length(feetPlayerPos), c, b);
				rayData = mix(rayData, rayCol, fog);
			}
			return (rayData * volMult) * lightCol;
		#endif
	#endif
}