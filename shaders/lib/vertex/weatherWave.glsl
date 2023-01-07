vec2 getWeatherWave(in vec3 vertexPlayerPos, in vec2 worldPos){
    // Get wave coord
    vec2 waveCoord = (worldPos + newFrameTimeCounter * WIND_SPEED) * 0.5;
    // Apply wave animation
    return vertexPlayerPos.xz + vertexPlayerPos.y * vec2(cos(waveCoord.x), sin(waveCoord.y)) * 0.25;
}