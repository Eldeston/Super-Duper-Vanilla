// Wave animation movements for gbuffers_terrain
vec3 getTerrainWave(in vec3 vertexPlayerPos, in vec3 worldPos, in float midBlockY, in float id, in float outside){
    // Wind affected blocks
    if(WIND_SPEED > 0){
        // Calculate wind strength
        float windStrength = sin(-sumOf(id == 10801 ? floor(worldPos.xz) : worldPos.xz) * WIND_FREQUENCY + newFrameTimeCounter * WIND_SPEED) * outside;

        // Simple blocks, horizontal movement
        if(id >= 10000 && id <= 10499){
            vertexPlayerPos.xz += windStrength * 0.1;
            return vertexPlayerPos;
        }

        // Single and double grounded cutouts
        if(id >= 10600 && id <= 10700){
            float isUpper = id == 10700 ? midBlockY - 1.5 : midBlockY - 0.5;
            vertexPlayerPos.xz += isUpper * windStrength * 0.125;
            return vertexPlayerPos;
        }

        // Single hanging cutouts
        if(id == 10800 || id == 10801){
            float isLower = midBlockY + 0.5;
            vertexPlayerPos.xz += isLower * windStrength * 0.125;
            return vertexPlayerPos;
        }

        // Multi wall cutouts
        if(id == 10900){
            vertexPlayerPos.xz += windStrength * 0.05;
            return vertexPlayerPos;
        }
    }

    // Current affected blocks
    if(CURRENT_SPEED > 0){
        // Calculate current strength
        float currentStrength = cos(-sumOf(worldPos.xz) * CURRENT_FREQUENCY + newFrameTimeCounter * CURRENT_SPEED);

        // Simple blocks, vertical movement
        if(id == 11100 || id == 11101){
            vertexPlayerPos.y += currentStrength * 0.0625;
            return vertexPlayerPos;
        }

        // Single and double grounded cutouts
        if(id == 11600){
            float isUpper = midBlockY - 0.5;
            vertexPlayerPos.xz += isUpper * currentStrength * 0.125;
            return vertexPlayerPos;
        }
    }

    return vertexPlayerPos;
}