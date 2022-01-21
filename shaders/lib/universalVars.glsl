#ifdef USE_SKY_LIGHTMAP
    float eyeBrightFact = eyeBrightnessSmooth.y / 240.0;
#else
    float eyeBrightFact = SKY_LIGHT_AMOUNT;
#endif

float torchBrightFact = eyeBrightnessSmooth.x / 240.0;

float newDawnDusk = smoothstep(0.32, 0.96, dawnDusk);
float newTwilight = cubed(twilight);

float newRainStrength = saturate(rainStrength * eyeBrightFact * float(isEyeInWater != 1));
float rainMult = newRainStrength + 1.0;
float underWaterMult = isEyeInWater + 1.0;

float ambientLighting = pow(AMBIENT_LIGHTING + nightVision * 0.5, GAMMA);

#ifdef ENABLE_LIGHT
    #ifdef USE_CUSTOM_LIGHTCOL
        vec3 lightCol = pow(USE_CUSTOM_LIGHTCOL, vec3(GAMMA)) * (1.0 - newTwilight);
    #else
        vec3 lightCol = pow(toneSaturation(mix(mix(vec3(LIGHT_COL_NIGHT_R, LIGHT_COL_NIGHT_G, LIGHT_COL_NIGHT_B), vec3(LIGHT_COL_DAY_R, LIGHT_COL_DAY_G, LIGHT_COL_DAY_B), day), vec3(LIGHT_COL_DAWN_DUSK_R, LIGHT_COL_DAWN_DUSK_G, LIGHT_COL_DAWN_DUSK_B), newDawnDusk), 1.0 - rainStrength * 0.5), vec3(GAMMA)) * (1.0 - newTwilight);
    #endif
#endif

#if defined USE_CUSTOM_FOGCOL
    vec3 skyCol = pow(USE_CUSTOM_FOGCOL, vec3(GAMMA));
#elif defined USE_VANILLA_FOGCOL
    vec3 skyCol = pow(USE_VANILLA_FOGCOL, vec3(GAMMA));
#else
    #ifdef USE_SKY_LIGHTMAP
        vec3 skyCol = pow(toneSaturation(mix(mix(vec3(SKY_COL_NIGHT_R, SKY_COL_NIGHT_G, SKY_COL_NIGHT_B), vec3(SKY_COL_DAY_R, SKY_COL_DAY_G, SKY_COL_DAY_B), day), vec3(SKY_COL_DAWN_DUSK_R, SKY_COL_DAWN_DUSK_G, SKY_COL_DAWN_DUSK_B), newDawnDusk), 1.0 - rainStrength * 0.5), vec3(GAMMA));
    #else
        vec3 skyCol = pow(toneSaturation(mix(mix(vec3(SKY_COL_NIGHT_R, SKY_COL_NIGHT_G, SKY_COL_NIGHT_B), vec3(SKY_COL_DAY_R, SKY_COL_DAY_G, SKY_COL_DAY_B), day), vec3(SKY_COL_DAWN_DUSK_R, SKY_COL_DAWN_DUSK_G, SKY_COL_DAWN_DUSK_B), newDawnDusk), 1.0 - rainStrength * 0.5), vec3(GAMMA));
    #endif
#endif