uniform vec3 fogColor;

uniform int isEyeInWater;

uniform float nightVision;

float ambientLighting = pow(AMBIENT_LIGHTING + nightVision * 0.5, GAMMA);

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
    const float newRainStrength = 0.0;
#else
    uniform float rainStrength;

    float newRainStrength = isEyeInWater != 1 ? rainStrength * eyeBrightFact : 0.0;
#endif

#ifdef WORLD_LIGHT
    // This macro gets the world light color data
    LIGHT_COL_DATA_BLOCK
#endif

// This macro gets the world sky color data
SKY_COL_DATA_BLOCK