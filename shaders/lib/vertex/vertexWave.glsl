// Wave calculation function
void getWave(inout vec3 vertexPos, in vec3 worldPos, in vec2 texCoord, in vec2 midTexCoord, in float id, in float outSide){
	float globalTime = ANIMATION_SPEED * frameTimeCounter;
	float offSet = float(texCoord.y < midTexCoord.y) + float(id == 10002);
	float plantWeight = 0.128; float waterWeight = 0.072;

	if((id >= 10000 && id <= 10003) || id == 10008){
		plantWeight *= offSet;
		waterWeight *= offSet;
	}

    float windDisp = sin(worldPos.x + worldPos.z * 2.0 + globalTime * 1.36) * plantWeight * outSide;
	float waterDisp = sin(worldPos.x + worldPos.z + globalTime * 1.6) * waterWeight;
	
	// Tall grass
	if((id >= 10000 && id <= 10003) || id == 10006) vertexPos.x += windDisp;
	// Foliage
	else if(id == 10005) vertexPos.xz += windDisp * 0.75;
	// Water and lava
    else if(id == 10010 || id == 10014) vertexPos.y += waterDisp;
	// Corals
	else if(id == 10008) vertexPos.x += waterDisp * 2.0;
	// Vines
    else if(id == 10007) vertexPos.x += windDisp * 0.32;
	// Floating plants
	else if(id == 10004) vertexPos.y += waterDisp;
}