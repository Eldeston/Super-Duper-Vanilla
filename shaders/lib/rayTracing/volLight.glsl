#ifdef VOL_LIGHT
#endif

vec3 getGodRays(vec3 feetPlayerPos, float worldPosY, float dither){
	#ifndef WORLD_LIGHT
		return vec3(0);
	#else
		// Return 0 if volumetric brightness is 0
		if(VOL_LIGHT_BRIGHTNESS == 0) return vec3(0);

		float c = WORLD_FOG_TOTAL_DENSITY * (isEyeInWater * 2.56 + newRainStrength + 1.0);
		float b = WORLD_FOG_VERTICAL_DENSITY;

		float nPlayerPosY = normalize(feetPlayerPos).y;

		#ifdef SHD_ENABLE
			feetPlayerPos *= 1.0 + dither * 0.3333;

			vec3 rayData = vec3(0);
			for(int x = 0; x < 7; x++){
				feetPlayerPos *= 0.736;
				rayData = mix(rayData, 
					getShdTex(distort(mat3(shadowProjection) * (mat3(shadowModelView) * feetPlayerPos + shadowModelView[3].xyz) + shadowProjection[3].xyz) * 0.5 + 0.5),
					atmoFog(nPlayerPosY, worldPosY, length(feetPlayerPos), c, b)
				);
			}
			
			return rayData;
		#else
			return vec3(atmoFog(nPlayerPosY, worldPosY, length(feetPlayerPos), c, b));
		#endif
	#endif
}