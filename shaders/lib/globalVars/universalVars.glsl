float eyeBrightFact = eyeBrightnessSmooth.y / 240.0;
float torchBrightFact = eyeBrightnessSmooth.x / 240.0;

float newDawnDusk = smoothstep(0.32, 0.96, dawnDusk);
float newTwilight = cubed(twilight);

float rainMult = 1.0 + rainStrength * eyeBrightFact * max(0.0, 1.0 - isEyeInWater);
float underWaterMult = isEyeInWater + 1.0;

float ambientLighting = AMBIENT_LIGHTING + nightVision;

#if defined USE_CUSTOM_LIGHTCOL
    vec3 lightCol = USE_CUSTOM_LIGHTCOL;
#else
    vec3 lightCol = mix(mix(LIGHT_COL_NIGHT, LIGHT_COL_DAY, day), LIGHT_COL_DAWN_DUSK, newDawnDusk);
#endif

#if defined USE_CUSTOM_FOGCOL
    vec3 skyCol = USE_CUSTOM_FOGCOL;
#elif defined USE_VANILLA_FOGCOL
    vec3 skyCol = USE_VANILLA_FOGCOL;
#else
    vec3 skyCol = toneSaturation(mix(mix(SKY_COL_NIGHT, SKY_COL_DAY, day), SKY_COL_DAWN_DUSK, newDawnDusk), 1.0 - rainStrength) * (eyeBrightFact * 0.5 + 0.5);
#endif