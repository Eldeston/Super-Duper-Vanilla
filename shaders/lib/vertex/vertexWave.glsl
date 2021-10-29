// Wave calculation function
void getWave(inout vec3 vertexPos, in vec3 worldPos, in vec2 texCoord, in vec2 midTexCoord, in float id, in float outSide){
	float animateTime = ANIMATION_SPEED * frameTimeCounter;
	float plantWeight = 0.128; float waterWeight = 0.072;

	if((id >= 10000 && id <= 10003) || id == 10008){
		float offSet = float(texCoord.y < midTexCoord.y) + float(id == 10002);
		
		plantWeight *= offSet;
		waterWeight *= offSet;
	}

    float windDisp = sin(worldPos.x + worldPos.z * 2.0 + animateTime * 1.32) * plantWeight * outSide;
	float waterDisp = sin(worldPos.x + worldPos.z + animateTime * 1.64) * waterWeight;
	
	#if defined TERRAIN || defined SHADOW
		// Tall grass
		if((id >= 10000 && id <= 10003) || id == 10006) vertexPos.x += windDisp;
		// Foliage
		if(id == 10005) vertexPos.xz += windDisp * 0.72;
		// Corals
		if(id == 10008) vertexPos.x += waterDisp * 2.4;
		// Vines
		if(id == 10007) vertexPos.x += windDisp * 0.32;
		// Floating plants
		if(id == 10004) vertexPos.y += waterDisp;
		// Lava
		if(id == 10017) vertexPos.y += waterDisp;
	#endif

	#if defined WATER || defined SHADOW
		// Water
		if(id == 10034) vertexPos.y += waterDisp;
	#endif
}