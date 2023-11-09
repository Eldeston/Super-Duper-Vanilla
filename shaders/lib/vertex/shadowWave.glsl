// Wave animation movements for shadow
vec3 getShadowWave(in vec3 vertexShdEyePlayerPos, in vec2 vertexShadowWorldPosXZ, in float midBlockY, in float id, in float outside){
    #ifdef TERRAIN_ANIMATION
        // Wind affected blocks
        if(WIND_SPEED > 0){
            // Calculate wind strength
            float windStrength = sin(-sumOf(id == 10801 ? floor(vertexShadowWorldPosXZ) : vertexShadowWorldPosXZ) * WIND_FREQUENCY + newFrameTimeCounter * WIND_SPEED) * outside;

            // Simple blocks, horizontal movement
            if(id >= 10000 && id <= 10499){
                vertexShdEyePlayerPos.xz += windStrength * 0.1;
                return vertexShdEyePlayerPos;
            }

            // Single and double grounded cutouts
            if(id >= 10600 && id <= 10700){
                float isUpper = id == 10700 ? midBlockY - 1.5 : midBlockY - 0.5;
                vertexShdEyePlayerPos.xz += isUpper * windStrength * 0.125;
                return vertexShdEyePlayerPos;
            }

            // Single hanging cutouts
            if(id == 10800 || id == 10801){
                float isLower = midBlockY + 0.5;
                vertexShdEyePlayerPos.xz += isLower * windStrength * 0.0625;
                return vertexShdEyePlayerPos;
            }

            // Multi wall cutouts
            if(id == 10900){
                vertexShdEyePlayerPos.xz += windStrength * 0.05;
                return vertexShdEyePlayerPos;
            }
        }
    #endif

    // Current affected blocks
    if(CURRENT_SPEED > 0){
        #if defined TERRAIN_ANIMATION || defined WATER_ANIMATION
            // Calculate current strength
            float currentStrength = cos(-sumOf(vertexShadowWorldPosXZ) * CURRENT_FREQUENCY + newFrameTimeCounter * CURRENT_SPEED);
        #endif

        #ifdef TERRAIN_ANIMATION
            // Simple blocks, vertical movement
            if(id == 11100 || id == 11101){
                vertexShdEyePlayerPos.y += currentStrength * 0.0625;
                return vertexShdEyePlayerPos;
            }

            // Single and double grounded cutouts
            if(id == 11600){
                float isUpper = midBlockY - 0.5;
                vertexShdEyePlayerPos.xz += isUpper * currentStrength * 0.125;
                return vertexShdEyePlayerPos;
            }
        #endif

        #if defined WATER_ANIMATION || defined PHYSICS_OCEAN
            // Water
            if(id == 11102){
                #ifdef PHYSICS_OCEAN
                    // basic texture to determine how shallow/far away from the shore the water is
                    float physics_localWaviness = texelFetch(physics_waviness, ivec2(gl_Vertex.xz) - physics_textureOffset, 0).r;

                    // transform gl_Vertex (since it is the raw mesh, i.e. not transformed yet)
                    vertexShdEyePlayerPos.y += physics_waveHeight((gl_Vertex.xz - physics_waveOffset) * PHYSICS_XZ_SCALE * physics_oceanWaveHorizontalScale, physics_localWaviness);
                #endif

                #ifdef WATER_ANIMATION
                    vertexShdEyePlayerPos.y += currentStrength * 0.0625;
                #endif

                return vertexShdEyePlayerPos;
            }
        #endif
    }

    return vertexShdEyePlayerPos;
}