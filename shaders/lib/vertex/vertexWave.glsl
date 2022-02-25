// Wave calculation function
void getWave(inout vec3 vertexPos, in vec3 worldPos, in vec2 texCoord, in vec2 midTexCoord, in float id, in float outSide){
	#ifdef WORLD_SKYLIGHT_AMOUNT
		outSide = WORLD_SKYLIGHT_AMOUNT;
	#endif

	float plantWeight = 0.128; float waterWeight = 0.072;

	// For grounded objects
	if((id >= 10005 && id <= 10007) || id == 10009 || (id >= 10013 && id <= 10015) || id == 10011 || id == 10036){
		float offSet = float(texCoord.y < midTexCoord.y) + float(id == 10007 || id == 10015);
		
		plantWeight *= offSet;
		waterWeight *= offSet;
	}

    float windDisp = sin(worldPos.x + worldPos.z * 2.0 + newFrameTimeCounter * 1.32 * WIND_SPEED) * plantWeight * outSide;
	float waterDisp = sin(worldPos.x + worldPos.z + newFrameTimeCounter * 1.64 * CURRENT_SPEED) * waterWeight;
	
	#if defined TERRAIN || defined SHADOW
		// Lava
		if(id == 10002) vertexPos.y += waterDisp;
		// Leaves
		if(id == 10004) vertexPos.xz += windDisp * 0.72;

		// Single and doubles land
		if((id >= 10005 && id <= 10009) || id == 10036) vertexPos.x += windDisp;
		// Sided land
		if(id == 10010) vertexPos.x += windDisp * 0.32;

		// Single and doubles underwater
		if(id >= 10011 && id <= 10015) vertexPos.x += waterDisp;

		// Floaters
		if(id == 10016) vertexPos.y += waterDisp;;
	#endif

	#if defined WATER || defined SHADOW
		// Water
		if(id == 10001) vertexPos.y += waterDisp;
	#endif
}