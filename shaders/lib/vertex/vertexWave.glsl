// Wave calculation function
void getWave(inout vec3 vertexPos, in vec3 worldPos, in vec2 texCoord, in vec2 midTexCoord, in float id){
    float plantWeight = 0.128;
    float waterWeight = 0.072;

	float globalTime = ANIMATION_SPEED * frameTimeCounter;
	
	if((id >= 10001 && id <= 10003) || id == 10004)
		plantWeight *= float(texCoord.y < midTexCoord.y) + float(id == 10003);

    float windDisp = sin(worldPos.x + worldPos.z * 2.0 + globalTime * 1.36) * plantWeight;
	float waterDisp = sin(worldPos.x + worldPos.z + globalTime * 1.6) * waterWeight;
	
	// Tall grass
	if(id >= 10001 && id <= 10004)
        vertexPos.x += windDisp;
	// Foliage
	else if(id == 10012)
		vertexPos.xz += windDisp * 0.75;
	// Water and lava
    else if(id == 10008 || id == 10006)
		vertexPos.y += waterDisp;
	// Vines
    else if(id == 10013)
		vertexPos.x += windDisp * 0.32;
	// Floating plants
	else if(id == 10011)
		vertexPos.y += waterDisp;
}