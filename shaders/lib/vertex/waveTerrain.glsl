// Distance from the wall a block is attached to (0 at the wall, 1 at the free end)
// dir: 0 = north, 1 = south, 2 = west, 3 = east (the direction the block faces, so the wall is on the opposite side)
float getWallDistance(in float dir, in vec3 midBlock){
    float axis = dir < 1.5 ? midBlock.z : midBlock.x;
    float wallSign = mod(dir, 2.0) < 0.5 ? 1.0 : -1.0;
    return axis * wallSign + 0.5;
}

// Wave animation movements for shadow
// midBlock is the offset from the vertex to the block center in blocks (at_midBlock / 64)
// vertexNormal must be the raw world aligned vertex normal (not the view space one)
vec3 getTerrainWave(in vec3 vertexEyePlayerPos, in vec2 vertexWorldPosXZ, in vec3 midBlock, in vec3 vertexNormal, in float id, in float outside, in float currTime){
    // Wind affected blocks (land ids only)
    if(WIND_SPEED > 0 && id >= 10000 && id < 11000){
        // Calculate wind strength
        float windStrength = sin(-sumOf(id == 10801 ? floor(vertexWorldPosXZ) : vertexWorldPosXZ) * WIND_FREQUENCY + currTime * WIND_SPEED) * outside;

        // Simple blocks, horizontal movement
        if(id >= 10000 && id <= 10099){
            vertexEyePlayerPos.xz -= windStrength * 0.1;
            return vertexEyePlayerPos;
        }

        // Single and double grounded cutouts
        if(id >= 10600 && id <= 10799){
            float isUpper = midBlock.y - (id >= 10700 ? 1.5 : 0.5);
            vertexEyePlayerPos.xz += isUpper * windStrength * 0.1;
            return vertexEyePlayerPos;
        }

        // Single hanging cutouts
        if(id >= 10800 && id <= 10899){
            float isLower = midBlock.y + 0.5;
            vertexEyePlayerPos.xz += isLower * windStrength * 0.05;
            return vertexEyePlayerPos;
        }

        // Multi wall cutouts (vines)
        // Slides along the wall and only ever pushes away from it, so it never clips into the wall
        if(id >= 10900 && id <= 10999){
            // Faces lying flat (attached to ceilings) stay still
            if(abs(vertexNormal.y) > 0.5) return vertexEyePlayerPos;

            // The wall axis comes from the normal, away from the wall is the direction towards the block center
            bool wallOnX = abs(vertexNormal.x) > abs(vertexNormal.z);
            float away = wallOnX ? midBlock.x : midBlock.z;

            vec2 alongWall = wallOnX ? vec2(0, 1) : vec2(1, 0);
            vec2 awayWall = wallOnX ? vec2(1, 0) : vec2(0, 1);

            vertexEyePlayerPos.xz += alongWall * windStrength * 0.05;
            vertexEyePlayerPos.xz += awayWall * sign(away) * (windStrength * 0.1 + 0.05);
            return vertexEyePlayerPos;
        }
    }

    // Current affected blocks (water ids only)
    if(CURRENT_SPEED > 0 && id >= 11000 && id < 12000){
        // Calculate current strength
        float currentStrength = cos(-sumOf(vertexWorldPosXZ) * CURRENT_FREQUENCY + currTime * CURRENT_SPEED);

        // Simple blocks, vertical movement
        if(id >= 11100 && id <= 11199){
            vertexEyePlayerPos.y += currentStrength * 0.05;
            return vertexEyePlayerPos;
        }

        // Overhanged wall cutouts (wall fans), the free end sways while the wall side stays put
        if(id >= 11200 && id <= 11599){
            float wallDistance = getWallDistance(floor((id - 11200.0) * 0.01 + 0.5), midBlock);
            vertexEyePlayerPos.xz -= wallDistance * currentStrength * 0.1;
            return vertexEyePlayerPos;
        }

        // Single and double grounded cutouts
        if(id >= 11600 && id <= 11799){
            float isUpper = midBlock.y - (id >= 11700 ? 1.5 : 0.5);
            vertexEyePlayerPos.xz += isUpper * currentStrength * 0.1;
            return vertexEyePlayerPos;
        }
    }

    return vertexEyePlayerPos;
}