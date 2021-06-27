float eyeBrightFact = eyeBrightnessSmooth.y / 240.0;
float torchBrightFact = eyeBrightnessSmooth.x / 240.0;

float newDawnDusk = smoothstep(0.32, 0.96, dawnDusk);
float newTwilight = smoothstep(0.64, 0.96, twilight);

#if defined COMPOSITE || defined DEFERRED || defined GBUFFERS
    float ambientLighting = AMBIENT_LIGHTING + nightVision;

    #ifdef END
        vec3 lightCol = LIGHT_COL_END;
        vec3 skyCol = SKY_COL_END;
    #else
        vec3 lightCol = mix(mix(LIGHT_COL_NIGHT, LIGHT_COL_DAY, day), LIGHT_COL_DAWN_DUSK, newDawnDusk) * (1.0 - rainStrength * 0.5);
        vec3 skyCol = toneSaturation(mix(mix(SKY_COL_NIGHT, SKY_COL_DAY, day), SKY_COL_DAWN_DUSK, newDawnDusk), 1.0 - rainStrength) * (eyeBrightFact * 0.5 + 0.5);
    #endif
#endif