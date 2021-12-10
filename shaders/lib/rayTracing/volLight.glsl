#ifdef VOL_LIGHT
#endif

vec3 getGodRays(vec3 feetPlayerPos, float worldPosY, float dither){
	#ifndef ENABLE_LIGHT
		return vec3(0);
	#else
		float c = FOG_TOTAL_DENSITY_FALLOFF * (1.0 + isEyeInWater * 2.5 + rainStrength);
		float b = FOG_VERTICAL_DENSITY_FALLOFF;

		float nPlayerPosY = normalize(feetPlayerPos).y;

		#if !(defined VOL_LIGHT && defined SHD_ENABLE)
			return vec3(atmoFog(nPlayerPosY, worldPosY, length(feetPlayerPos), c, b));
		#else
			if(VOL_LIGHT_BRIGHTNESS == 0) return vec3(0);
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
		#endif
	#endif
}