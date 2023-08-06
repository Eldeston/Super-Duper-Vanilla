// Wave animation movements for shadow
vec3 getShadowWave(in vec3 vertexPlayerPos, in vec3 worldPos, in float midBlockY, in float id, in float outside){
    #ifdef TERRAIN_ANIMATION
        // Wind affected blocks
        if(WIND_SPEED > 0){
            // Calculate wind strength
            float windStrength = sin(-sumOf(id == 13001 ? floor(worldPos.xz) : worldPos.xz) * WIND_FREQUENCY + newFrameTimeCounter * WIND_SPEED) * outside;

            // Simple blocks, horizontal movement
            if(id >= 10000 && id <= 10499){
                vertexPlayerPos.xz += windStrength * 0.1;
                return vertexPlayerPos;
            }

            // Single and double grounded cutouts
            if(id >= 12000 && id <= 12500){
                float isUpper = id == 12500 ? midBlockY - 1.5 : midBlockY - 0.5;
                vertexPlayerPos.xz += isUpper * windStrength * 0.125;
                return vertexPlayerPos;
            }

            // Single hanging cutouts
            if(id == 13000 || id == 13001){
                float isLower = midBlockY + 0.5;
                vertexPlayerPos.xz += isLower * windStrength * 0.0625;
                return vertexPlayerPos;
            }

            // Multi wall cutouts
            if(id == 14000){
                vertexPlayerPos.xz += windStrength * 0.05;
                return vertexPlayerPos;
            }
        }
    #endif

    // Current affected blocks
    if(CURRENT_SPEED > 0){
        #if defined TERRAIN_ANIMATION || defined WATER_ANIMATION
            // Calculate current strength
            float currentStrength = cos(-sumOf(worldPos.xz) * CURRENT_FREQUENCY + newFrameTimeCounter * CURRENT_SPEED);
        #endif

        #ifdef TERRAIN_ANIMATION
            // Simple blocks, vertical movement
            if(id == 15500 || id == 15501){
                vertexPlayerPos.y += currentStrength * 0.0625;
                return vertexPlayerPos;
            }

            // Single and double grounded cutouts
            if(id == 17000){
                float isUpper = midBlockY - 0.5;
                vertexPlayerPos.xz += isUpper * currentStrength * 0.125;
                return vertexPlayerPos;
            }
        #endif

        #if defined WATER_ANIMATION || defined PHYSICS_OCEAN
            // Water
            if(id == 15502){
                #ifdef PHYSICS_OCEAN
                    // basic texture to determine how shallow/far away from the shore the water is
                    float physics_localWaviness = texelFetch(physics_waviness, ivec2(gl_Vertex.xz) - physics_textureOffset, 0).r;

                    // transform gl_Vertex (since it is the raw mesh, i.e. not transformed yet)
                    vertexPlayerPos.y += physics_waveHeight((gl_Vertex.xz - physics_waveOffset) * PHYSICS_XZ_SCALE * physics_oceanWaveHorizontalScale, physics_localWaviness);
                #endif

                #ifdef WATER_ANIMATION
                    vertexPlayerPos.y += currentStrength * 0.0625;
                #endif

                return vertexPlayerPos;
            }
        #endif
    }

    return vertexPlayerPos;
}