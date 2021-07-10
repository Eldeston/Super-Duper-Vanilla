vec3 getGodRays(vec3 feetPlayerPos, float worldPosY, float dither){
	#if defined NETHER || defined END
		return vec3(0);
	#else
		float c = HEIGHT_FOG_DENSITY * rainMult * underWaterMult * 1.44; float b = FOG_DENSITY * rainMult * underWaterMult * 1.44;

		#ifndef VOL_LIGHT
			return vec3(atmoFog(feetPlayerPos.y, worldPosY, length(feetPlayerPos), c, b));
		#else
			if(VOL_LIGHT_BRIGHTNESS == 0) return vec3(0);
			feetPlayerPos *= 1.0 + dither * 0.3333;

			vec3 rayData = vec3(0);
			for(int x = 0; x < 8; x++){
				feetPlayerPos *= 0.766;
				rayData = mix(rayData, getShdTex(distort(toShadow(feetPlayerPos).xyz) * 0.5 + 0.5), atmoFog(feetPlayerPos.y, worldPosY, length(feetPlayerPos), c, b));
			}
			
			return rayData;
		#endif
	#endif
}