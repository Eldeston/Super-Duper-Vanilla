#ifdef WORLD_SKYLIGHT_AMOUNT
    const float eyeBrightFact = WORLD_SKYLIGHT_AMOUNT;
#else
    float eyeBrightFact = eyeBrightnessSmooth.y / 240.0;
#endif

float torchBrightFact = eyeBrightnessSmooth.x / 240.0;

float newDawnDusk = smoothstep(0.32, 0.96, dawnDusk);

float newRainStrength = saturate(rainStrength * eyeBrightFact * float(isEyeInWater != 1));
float rainMult = newRainStrength + 1.0;
float underWaterMult = isEyeInWater + 1.0;

float ambientLighting = pow(AMBIENT_LIGHTING + nightVision * 0.5, GAMMA);

// This macro gets the world light color data
LIGHT_COL_DATA_BLOCK

// This macro gets the world sky color data
SKY_COL_DATA_BLOCK