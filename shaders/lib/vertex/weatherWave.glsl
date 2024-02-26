vec2 getWeatherWave(in vec3 vertexEyePlayerPos, in vec2 vertexWorldPosXZ){
    // Get wave coord
    float windStrength = sin(-sumOf(vertexWorldPosXZ) * WIND_FREQUENCY * 0.5 + vertexFrameTime * WIND_SPEED);
    // Apply wave animation
    return vertexEyePlayerPos.xz + vertexEyePlayerPos.y * windStrength * 0.25;
}