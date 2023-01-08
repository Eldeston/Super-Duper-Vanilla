// Wave animation movements for shadow
vec3 getTerrainWave(in vec3 vertexPlayerPos, in vec3 worldPos, in float texCoordY, in float midTexCoordY, in float id, in float outside){
    #ifdef TERRAIN_ANIMATION
        // Wind affected blocks
        if(WIND_SPEED > 0){
            // Calculate wind strength
            float windStrength = sin(sumOf(worldPos.xz) * 0.5 + newFrameTimeCounter * WIND_SPEED) * outside;

            // Single and double grounded cutouts
            if((id >= 10000 && id <= 10003) || id == 10036){
                float isUpper = float(texCoordY < midTexCoordY) + float(id == 10003);
                vertexPlayerPos.xz += isUpper * windStrength * 0.125;
                return vertexPlayerPos;
            }

            // Single hanging cutouts
            if(id == 10004){
                float isLower = float(texCoordY > midTexCoordY);
                vertexPlayerPos.xz += isLower * windStrength * 0.125;
                return vertexPlayerPos;
            }

            // Multi cutouts and blocks
            if(id == 10005 || id == 10007 || id == 10033){
                vertexPlayerPos.xz += windStrength * 0.1;
                return vertexPlayerPos;
            }

            // Multi wall cutouts
            if(id == 10006){
                vertexPlayerPos.xz += windStrength * 0.05;
                return vertexPlayerPos;
            }

            // Lantern
            if(id == 10051){
                float isLower = 1.0 - fract(worldPos.y - 0.005);
                vertexPlayerPos.xz += isLower * windStrength * 0.0625;
                return vertexPlayerPos;
            }
        }
    #endif

    // Current affected blocks
    if(CURRENT_SPEED > 0){
        #if defined TERRAIN_ANIMATION || defined TERRAIN_ANIMATION
            // Calculate current strength
            float currentStrength = cos(sumOf(worldPos.xz) + newFrameTimeCounter * CURRENT_SPEED);
        #endif

        #ifdef TERRAIN_ANIMATION
            // Single and double grounded cutouts
            if(id >= 10010 && id <= 10012){
                float isUpper = float(texCoordY < midTexCoordY) + float(id == 10012);
                vertexPlayerPos.xz += isUpper * currentStrength * 0.125;
                return vertexPlayerPos;
            }

            // Multi cutouts
            if(id == 10013){
                vertexPlayerPos.xz += currentStrength * 0.0625;
                return vertexPlayerPos;
            }

            // Floaters
            if(id == 10014){
                vertexPlayerPos.y += currentStrength * 0.0625;
                return vertexPlayerPos;
            }

            // Lava
            if(id == 10016){
                vertexPlayerPos.y += currentStrength * 0.0625;
                return vertexPlayerPos;
            }
        #endif

        #ifdef WATER_ANIMATION
            // Water
            if(id == 10015){
                vertexPlayerPos.y += currentStrength * 0.0625;
                return vertexPlayerPos;
            }
        #endif
    }

    return vertexPlayerPos;
}