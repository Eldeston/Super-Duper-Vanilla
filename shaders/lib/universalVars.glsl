#ifdef WORLD_SKYLIGHT_AMOUNT
    const float eyeBrightFact = WORLD_SKYLIGHT_AMOUNT;
#else
    float eyeBrightFact = eyeBrightnessSmooth.y / 240.0;
#endif

float torchBrightFact = eyeBrightnessSmooth.x / 240.0;

float newDawnDusk = smoothstep(0.32, 0.96, dawnDusk);
float newTwilight = cubed(twilight);

float newRainStrength = saturate(rainStrength * eyeBrightFact * float(isEyeInWater != 1));
float rainMult = newRainStrength + 1.0;
float underWaterMult = isEyeInWater + 1.0;

float ambientLighting = pow(AMBIENT_LIGHTING + nightVision * 0.5, GAMMA);

#ifdef WORLD_LIGHT
    #ifdef USE_CUSTOM_LIGHTCOL
        vec3 lightCol = pow(USE_CUSTOM_LIGHTCOL, vec3(GAMMA)) * (1.0 - newTwilight);
    #else
        vec3 lightCol = pow(toneSaturation(mix(mix(LIGHT_N, LIGHT_D, day), LIGHT_DD, newDawnDusk) * 0.00392156863, 1.0 - rainStrength * 0.5), vec3(GAMMA)) * (1.0 - newTwilight);
    #endif
#endif

#if defined WORLD_CUSTOM_FOGCOL
    const vec3 skyCol = pow(WORLD_CUSTOM_FOGCOL, vec3(GAMMA));
#elif defined WORLD_VANILLA_FOGCOL
    vec3 skyCol = pow(WORLD_VANILLA_FOGCOL, vec3(GAMMA));
#else
    vec3 skyCol = pow(toneSaturation(mix(mix(SKY_N, SKY_D, day), SKY_DD, newDawnDusk) * 0.00392156863, 1.0 - rainStrength * 0.5), vec3(GAMMA));
#endif