// Wave animation movements for gbuffers_terrain
vec3 getTerrainWave(in vec3 vertexFeetPlayerPos, in vec3 vertexWorldPos, in float midBlockY, in float id, in float outside, in float currTime){
    // Wind affected blocks
    if(WIND_SPEED > 0){
        // Calculate wind strength
        float windStrength = sin(-sumOf(id == 10801 ? floor(vertexWorldPos.xz) : vertexWorldPos.xz) * WIND_FREQUENCY + currTime * WIND_SPEED) * outside;

        // Simple blocks, horizontal movement
        if(id >= 10000 && id <= 10499){
            vertexFeetPlayerPos.xz += windStrength * 0.1;
            return vertexFeetPlayerPos;
        }

        // Single and double grounded cutouts
        if(id >= 10600 && id <= 10700){
            float isUpper = id == 10700 ? midBlockY - 1.5 : midBlockY - 0.5;
            vertexFeetPlayerPos.xz += isUpper * windStrength * 0.125;
            return vertexFeetPlayerPos;
        }

        // Single hanging cutouts
        if(id == 10800 || id == 10801){
            float isLower = midBlockY + 0.5;
            vertexFeetPlayerPos.xz += isLower * windStrength * 0.125;
            return vertexFeetPlayerPos;
        }

        // Multi wall cutouts
        if(id == 10900){
            vertexFeetPlayerPos.xz += windStrength * 0.05;
            return vertexFeetPlayerPos;
        }
    }

    // Current affected blocks
    if(CURRENT_SPEED > 0){
        // Calculate current strength
        float currentStrength = cos(-sumOf(vertexWorldPos.xz) * CURRENT_FREQUENCY + currTime * CURRENT_SPEED);

        // Simple blocks, vertical movement
        if(id == 11100 || id == 11101){
            vertexFeetPlayerPos.y += currentStrength * 0.0625;
            return vertexFeetPlayerPos;
        }

        // Single and double grounded cutouts
        if(id == 11600){
            float isUpper = midBlockY - 0.5;
            vertexFeetPlayerPos.xz += isUpper * currentStrength * 0.125;
            return vertexFeetPlayerPos;
        }
    }

    return vertexFeetPlayerPos;
}