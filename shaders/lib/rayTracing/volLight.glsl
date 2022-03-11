#ifdef VOL_LIGHT
#endif

vec3 getGodRays(vec3 feetPlayerPos, float dither){
	#ifndef WORLD_LIGHT
		return vec3(0);
	#else
		// Return 0 if volumetric brightness is 0
		if(VOL_LIGHT_BRIGHTNESS == 0) return vec3(0);

		float c = WORLD_FOG_TOTAL_DENSITY * (isEyeInWater * 2.56 + newRainStrength + 1.0);
		float b = WORLD_FOG_VERTICAL_DENSITY * 1.6;

		float nPlayerPosY = normalize(feetPlayerPos).y;

		#ifdef SHD_ENABLE
			vec3 endPos = feetPlayerPos * 0.125;
			vec3 startPos = endPos * dither;

			vec3 rayData = vec3(0);
			for(int x = 0; x < 7; x++){
				startPos += endPos;
				rayData = mix(rayData, 
					getShdTex(distort(mat3(shadowProjection) * (mat3(shadowModelView) * startPos + shadowModelView[3].xyz) + shadowProjection[3].xyz) * 0.5 + 0.5),
					atmoFog(nPlayerPosY, startPos.y + cameraPosition.y, length(startPos), c, b)
				);
			}
			
			return rayData;
		#else
			return vec3(atmoFog(nPlayerPosY, feetPlayerPos.y + cameraPosition.y, length(feetPlayerPos), c, b));
		#endif
	#endif
}