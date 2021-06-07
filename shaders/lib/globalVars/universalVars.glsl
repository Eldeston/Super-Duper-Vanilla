float eyeBrightFact = eyeBrightnessSmooth.y / 240.0;

float newDawnDusk = smoothstep(0.32, 0.96, dawnDusk);
float newTwilight = smoothstep(0.64, 0.96, twilight);

vec3 skyCol = toneSaturation(mix(mix(SKY_COL_NIGHT, SKY_COL_DAY, day), SKY_COL_DAWN_DUSK, newDawnDusk), 1.0 - rainStrength);
vec3 lightCol = mix(mix(LIGHT_COL_NIGHT, LIGHT_COL_DAY, day), LIGHT_COL_DAWN_DUSK, newDawnDusk) * (1.0 - rainStrength * 0.5);