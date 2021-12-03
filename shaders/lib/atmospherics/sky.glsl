float getStarShape(vec2 st, float size){
    return smoothstep(0.032, 0.016, max2(abs(st)) / size);
}

float getSunMoonShape(vec2 pos){
    return exp2(-(sqrt(sqrt(pos.x * pos.x * pos.x * pos.x + pos.y * pos.y * pos.y * pos.y)) - 0.064) * 128.0);
}

float genStar(vec2 nSkyPos){
	vec2 starRand = getRandTex(nSkyPos, 1).xy;
    vec2 starGrid = 0.5 * sin(starRand * 12.0 + 128.0) - fract(nSkyPos * noiseTextureResolution) + 0.5;
    return getStarShape(starGrid, starRand.x * 0.9 + 0.3);
}

float cloudParallax(vec2 pos, float time, int steps){
	vec2 uv = pos / 64.0;
	float invSteps = 1.0 / steps;

	vec2 start = uv;
	vec2 end = start * invSteps * 0.16;

	float tex = 0.0;
	for(int i = 0; i < steps; i++){
		start -= end;
		tex += texture2D(colortex7, start + vec2(0, time * 0.001)).r;
	}
	
	return tex * invSteps;
}

vec3 getSkyColor(vec3 nSkyPos, vec3 nPlayerPos, bool skyDiffuseMask){
    if(isEyeInWater == 2) return pow(fogColor, vec3(GAMMA));

    #ifdef SKY_GROUND_COL
        float c = FOG_TOTAL_DENSITY_FALLOFF * (1.0 + isEyeInWater * 2.5 + rainStrength) * PI2;
        float skyPlaneFog = nPlayerPos.y < 0.0 ? exp(length(nPlayerPos.xz) * c / nPlayerPos.y) : 0.0;
        vec3 finalCol = mix(skyCol, SKY_GROUND_COL * (skyCol + lightCol + ambientLighting), skyPlaneFog);
    #else
        vec3 finalCol = skyCol;
    #endif

    #ifdef USE_HORIZON_COL
        finalCol += USE_HORIZON_COL * squared(1.0 - abs(nPlayerPos.y));
    #endif

    if(isEyeInWater == 1){
        float waterVoid = smootherstep(nPlayerPos.y + (eyeBrightFact - 0.64));
        finalCol = mix(fogColor * lightCol, skyCol, waterVoid);
    }

    #ifdef USE_SUN_MOON
        if(skyDiffuseMask){
            float lightRange = pow(max(-nSkyPos.z * 0.5, 0.0), abs(nPlayerPos.y) + 1.0) * (1.0 - newTwilight);
            finalCol += lightCol * lightRange;
        }
    #endif

    /*
    vec2 plane = nPlayerPos.xz / nPlayerPos.y;
    float clouds = cloudParallax(plane, frameTimeCounter, 16);
    finalCol = mix(finalCol, ambientLighting + skyCol + lightCol * (1.0 - clouds), clouds * smootherstep(nPlayerPos.y * 2.0));
    */
    
    return pow(finalCol, vec3(GAMMA));
}

vec3 getSkyRender(vec3 playerPos, bool skyDiffuseMask){
    return getSkyColor(normalize(mat3(shadowProjection) * (mat3(shadowModelView) * playerPos)), normalize(playerPos), skyDiffuseMask);
}

vec3 getSkyRender(vec3 playerPos, bool skyDiffuseMask, bool skyMask, bool sunMoonMask){
    vec3 nPlayerPos = normalize(playerPos);
    vec3 nSkyPos = normalize(mat3(shadowProjection) * (mat3(shadowModelView) * playerPos));

    vec3 finalCol = getSkyColor(nSkyPos, nPlayerPos, skyDiffuseMask);

    #if defined USE_SUN_MOON && !defined VANILLA_SUN_MOON
        if(sunMoonMask) finalCol += getSunMoonShape(nSkyPos.xy) * 2.0;
    #endif

    #ifdef USE_STARS_COL
        if(skyMask){
            // Stars
            vec2 starPos = 0.5 > abs(nSkyPos.y) ? vec2(atan(nSkyPos.x, nSkyPos.z), nSkyPos.y) * 0.25 : nSkyPos.xz * 0.333;
            finalCol = max(finalCol, USE_STARS_COL * genStar(starPos * 0.128));
        }
    #endif

    return finalCol;
}