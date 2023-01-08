// Wave animation movements for gbuffers_water
float getWaterWave(in vec2 worldPos, in float vertexPosY){
    // Calculate current strength
    float currentStrength = cos(sumOf(worldPos) + newFrameTimeCounter * CURRENT_SPEED);

    // Apply wave animation
    return vertexPosY + currentStrength * 0.0625;
}