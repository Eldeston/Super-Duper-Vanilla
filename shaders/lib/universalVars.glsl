uniform int isEyeInWater;

uniform float nightVision;
uniform float rainStrength;

uniform float day;
uniform float dawnDusk;

uniform vec3 fogColor;

#ifdef WORLD_SKYLIGHT_AMOUNT
    const float eyeBrightFact = WORLD_SKYLIGHT_AMOUNT;
#else
    uniform ivec2 eyeBrightnessSmooth;
    
    float eyeBrightFact = eyeBrightnessSmooth.y / 240.0;
#endif

float newRainStrength = isEyeInWater != 1 ? saturate(rainStrength * eyeBrightFact) : 0.0;

float ambientLighting = pow(AMBIENT_LIGHTING + nightVision * 0.5, GAMMA);

#ifdef WORLD_LIGHT
    // This macro gets the world light color data
    LIGHT_COL_DATA_BLOCK
#endif

// This macro gets the world sky color data
SKY_COL_DATA_BLOCK