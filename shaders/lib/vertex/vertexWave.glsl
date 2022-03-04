// Wave calculation function
void getWave(inout vec3 vertexPos, in vec3 worldPos, in vec2 texCoord, in vec2 midTexCoord, in float id, in float outSide){
	#ifdef WORLD_SKYLIGHT_AMOUNT
		outSide = WORLD_SKYLIGHT_AMOUNT;
	#endif

	float plantWeight = 0.128; float waterWeight = 0.072;

	// For grounded objects
	if((id >= 10005 && id <= 10007) || (id >= 10010 && id <= 10012) || id == 10036){
		float offSet = float(texCoord.y < midTexCoord.y) + float(id == 10007 || id == 10012);
		
		plantWeight *= offSet;
		waterWeight *= offSet;
	}

	// For hanged objects
	if(id == 10015){
		float offSet = float(texCoord.y > midTexCoord.y);
		
		plantWeight *= offSet;
		waterWeight *= offSet;
	}

	// Lantern
	if(id == 10039){
		float offSet = 1.0 - sqrt(fract(worldPos.y - 0.001));

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

		// Single and doubles grounded and hanged land
		if((id >= 10005 && id <= 10008) || id == 10015 || id == 10033 || id == 10036) vertexPos.x += windDisp;
		// Sided land
		if(id == 10009) vertexPos.x += windDisp * 0.32;

		// Single and doubles grounded and hanged underwater
		if(id >= 10010 && id <= 10013) vertexPos.x += waterDisp;

		// Floaters
		if(id == 10014) vertexPos.y += waterDisp;;

		// Lanterns
		if(id == 10039) vertexPos.xz += windDisp * 0.5;
	#endif

	#if defined WATER || defined SHADOW
		// Water
		if(id == 10001) vertexPos.y += waterDisp;
	#endif
}