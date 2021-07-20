vec3 getGodRays(vec3 feetPlayerPos, float worldPosY, float dither){
	#if defined NETHER || defined END
		return vec3(0);
	#else
		float c = FOG_TOTAL_DENSITY_FALLOFF * rainMult * underWaterMult;
		float b = FOG_VERTICAL_DENSITY_FALLOFF * rainMult * underWaterMult;
		worldPosY /= (1.0 + rainStrength * 4.0);

		#if !(defined VOL_LIGHT && defined SHD_ENABLE)
			return vec3(atmoFog(feetPlayerPos.y, worldPosY, length(feetPlayerPos), c, b));
		#else
			if(VOL_LIGHT_BRIGHTNESS == 0) return vec3(0);
			feetPlayerPos *= 1.0 + dither * 0.3333;

			vec3 rayData = vec3(0);
			for(int x = 0; x < 7; x++){
				feetPlayerPos *= 0.736;
				rayData = mix(rayData, getShdTex(distort(toShadow(feetPlayerPos).xyz) * 0.5 + 0.5), atmoFog(feetPlayerPos.y, worldPosY, length(feetPlayerPos), c, b));
			}
			
			return rayData;
		#endif
	#endif
}