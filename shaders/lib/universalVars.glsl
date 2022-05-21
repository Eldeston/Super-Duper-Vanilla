uniform vec3 fogColor;

#if WORLD_ID == -1
    // Uniforms for world-1 (Nether)
#elif WORLD_ID == 0
    // Uniforms for world0 (Overworld)
    uniform float day;
    uniform float dawnDusk;
#elif WORLD_ID == 1
    // Uniforms for world1 (End)
#endif

#ifdef WORLD_SKYLIGHT
    const float eyeBrightFact = WORLD_SKYLIGHT;
#else
    uniform ivec2 eyeBrightnessSmooth;
    
    float eyeBrightFact = eyeBrightnessSmooth.y * 0.00416667;
#endif

#ifdef FORCE_DISABLE_WEATHER
    const float rainStrength = 0.0;
#else
    uniform float rainStrength;
#endif