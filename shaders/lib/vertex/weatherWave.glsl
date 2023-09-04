vec2 getWeatherWave(in vec3 vertexPlayerPos, in vec2 vertexWorldPos){
    // Get wave coord
    float windStrength = sin(-sumOf(vertexWorldPos) * WIND_FREQUENCY * 0.5 + newFrameTimeCounter * WIND_SPEED);
    // Apply wave animation
    return vertexPlayerPos.xz + vertexPlayerPos.y * windStrength * 0.25;
}