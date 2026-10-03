// Wave animation movements for shadow
vec3 getWaterWave(in vec3 vertexEyePlayerPos, in vec2 vertexWorldPosXZ, in float id, in float currTime){
    // Current affected water blocks
    if(CURRENT_SPEED > 0.0 && id >= 11100.0 && id <= 11199.0){
        float currentStrength = cos(-sumOf(vertexWorldPosXZ) * CURRENT_FREQUENCY + currTime * CURRENT_SPEED);
        vertexEyePlayerPos.y += currentStrength * 0.05;
    }

    return vertexEyePlayerPos;
}