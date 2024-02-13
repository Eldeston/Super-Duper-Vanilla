// Wave animation movements for gbuffers_water
float getWaterWave(in vec2 vertexWorldPos, in float vertexPosY, in float currTime){
    // Calculate current strength
    float currentStrength = cos(-sumOf(vertexWorldPos) * CURRENT_FREQUENCY + currTime * CURRENT_SPEED);

    // Apply wave animation
    return vertexPosY + currentStrength * 0.0625;
}