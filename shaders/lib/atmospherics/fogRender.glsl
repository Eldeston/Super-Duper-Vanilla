#ifndef IS_PALE_GARDEN_DECLARED
    #define IS_PALE_GARDEN_DECLARED
    uniform float isPaleGarden;
#endif

#ifndef DYNAMIC_FOG_UNIFORM_DECLARED
    #define DYNAMIC_FOG_UNIFORM_DECLARED
    #ifdef DYNAMIC_FOG
        uniform float dynamicFog;
    #else
        const float dynamicFog = 0.0;
    #endif
#endif

// Modified Complementary border fog calculation, thanks Emin!
float getBorderFog(in float playerPosLength){
    return exp2(-exp2(playerPosLength / borderFar * 21.0 - 18.0));
}
// Ground fog calculation: stable optical depth integration through exponential atmosphere
// Prevents numerical explosion when looking downwards or at high altitudes
float getAtmosphericFog(in float nPlayerPosY, in float worldPosY, in float playerPosLength, in float totalDensity, in float verticalFogDensity){
    float camY = max(0.0, cameraPosition.y);
    float tgtY = max(0.0, worldPosY);
    float minY = min(camY, tgtY);
    float dy = abs(tgtY - camY);
    float k = max(0.0001, verticalFogDensity);
    float kDy = max(dy * k, 0.0001);
    float heightIntegral = (1.0 - exp2(-kDy)) / kDy;
    float opticalDepth = totalDensity * playerPosLength * exp2(-minY * k) * heightIntegral;
    return 1.0 - exp2(-opticalDepth);
}

#if WORLD_ID == 0 && defined PALE_GARDEN_FOG
vec3 getPaleGardenSkyColor(in vec3 nEyePlayerPos){
    #ifndef FORCE_DISABLE_DAY_CYCLE
        float dCycle = dayCycle;
    #else
        float dCycle = 1.0;
    #endif

    // Bright luminous silvery-gray mist in the sky
    vec3 paleSkyDay = toLinear(vec3(0.78, 0.79, 0.81));
    vec3 paleSkyTwilight = toLinear(vec3(0.48, 0.47, 0.50));
    vec3 paleSkyNight = toLinear(vec3(0.14, 0.15, 0.18));
    vec3 col = lerp(paleSkyNight, paleSkyTwilight, paleSkyDay, dCycle);

    #ifndef FORCE_DISABLE_WEATHER
        col = mix(col, toLinear(fogColor), weatherFade * 0.35);
    #endif

    // Soft forward sun glow through the mist during the day
    vec3 sunDir = vec3(shadowModelView[0].z, shadowModelView[1].z, shadowModelView[2].z);
    float sg = saturate(dot(nEyePlayerPos, sunDir) * 0.5 + 0.5);
    sg *= sg;
    float sunGlow = sg * sg;
    #ifndef WORLD_CUSTOM_SKYLIGHT
        col += toLinear(vec3(0.14, 0.12, 0.10)) * (sunGlow * saturate(dCycle - 1.0) * smoothstep(0.08, 0.40, eyeBrightFact));
    #else
        col += toLinear(vec3(0.14, 0.12, 0.10)) * (sunGlow * saturate(dCycle - 1.0));
    #endif

    return col;
}

vec3 getPaleGardenFogColor(in vec3 nEyePlayerPos){
    vec3 skyCol = getPaleGardenSkyColor(nEyePlayerPos);
    // Terrain fog is slightly deeper to create natural aerial perspective:
    // Distant terrain appears as a soft darker silhouette against the lighter sky
    return skyCol * mix(0.66, 0.72, saturate(nEyePlayerPos.y * 2.0));
}
#endif

#if WORLD_ID == 0 && defined PALE_GARDEN_FOG
vec3 applyPaleGardenFogColor(in vec3 baseFogCol, in vec3 nEyePlayerPos){
    if(isEyeInWater == 0 && PALE_GARDEN_FOG > 0.0 && isPaleGarden > 0.001 && effectFactor < 0.01){
        vec3 paleFogCol = getPaleGardenFogColor(nEyePlayerPos);
        return mix(baseFogCol, paleFogCol, isPaleGarden * min(1.0, PALE_GARDEN_FOG));
    }
    return baseFogCol;
}
#else
#define applyPaleGardenFogColor(col, nPos) (col)
#endif

#if WORLD_ID == 0 && defined DYNAMIC_FOG
void applyDynamicFogModifiers(inout float totalDensity, inout float verticalDensity, inout float maxCap){
    if(isEyeInWater != 0 || dynamicFog <= 0.001) return;
    totalDensity *= 1.0 + dynamicFog * 2.8;
    verticalDensity = mix(verticalDensity, verticalDensity * 1.35, dynamicFog * 0.5);
    maxCap = min(1.0, maxCap * (1.0 + dynamicFog * 0.6));
}
#else
#define applyDynamicFogModifiers(totalDensity, verticalDensity, maxCap)
#endif

#if WORLD_ID == 1 && defined END_BOSS_FOG
float getEndBossFogAmount(in float viewDist, in float worldPosY){
    bool isActive = isEyeInWater == 0 && END_BOSS_FOG > 0.0 && fogEnd <= 100.0 && (fogStart / max(fogEnd, 0.001)) < 0.60 && effectFactor < 0.01;
    if(!isActive) return 0.0;
    float bStart = max(0.0, fogStart * (0.8 / max(END_BOSS_FOG, 0.5)));
    float bEnd = max(bStart + 25.0, fogEnd * (1.1 / pow(END_BOSS_FOG, 0.35)));
    float bDistProgress = saturate((viewDist - bStart) / (bEnd - bStart));
    float bossDensity = 1.0 - exp2(-(bDistProgress * sqrt(sqrt(bDistProgress))) * (4.2 * END_BOSS_FOG));
    float heightFade = saturate(1.0 - max(0.0, worldPosY - 80.0) * 0.012);
    return bossDensity * mix(0.70, 1.0, heightFade);
}
#endif

#if WORLD_ID == 0 && defined PALE_GARDEN_FOG
float getPaleGardenFogAmount(in float viewDist, in float worldPosY){
    bool isActive = isEyeInWater == 0 && PALE_GARDEN_FOG > 0.0 && isPaleGarden > 0.001 && effectFactor < 0.01;
    if(!isActive) return 0.0;
    float pgStart = 12.0 / max(PALE_GARDEN_FOG, 0.5);
    float pgEnd = max(pgStart + 25.0, 70.0 / pow(PALE_GARDEN_FOG, 0.4));
    float pgDistProgress = saturate((viewDist - pgStart) / (pgEnd - pgStart));
    float pgDensity = 1.0 - exp2(-(pgDistProgress * sqrt(sqrt(sqrt(pgDistProgress)))) * (4.2 * PALE_GARDEN_FOG));
    float heightFade = saturate(1.0 - max(0.0, worldPosY - 105.0) * 0.016);
    return pgDensity * isPaleGarden * mix(0.70, 1.0, heightFade);
}
#endif

float getFogFactor(in float viewDist, in float nEyePlayerPosY, in float worldPosY){
    #ifdef FORCE_DISABLE_WEATHER
        float verticalFogDensity = isEyeInWater == 0 ? FOG_VERTICAL_DENSITY : FOG_VERTICAL_DENSITY * 0.2;
        float totalFogDensity = isEyeInWater == 0 ? FOG_TOTAL_DENSITY : FOG_TOTAL_DENSITY * TAU;
    #else
        // Gentle atmospheric rain haze instead of blinding opaque fog wall
        float verticalFogDensity = isEyeInWater == 0 ? FOG_VERTICAL_DENSITY * (1.0 - weatherFade * 0.20) : FOG_VERTICAL_DENSITY * 0.2;
        float totalFogDensity = isEyeInWater == 0 ? FOG_TOTAL_DENSITY * (1.0 + weatherFade * 0.45) : FOG_TOTAL_DENSITY * TAU;
    #endif

    // Return fog, capped with ground fog strength and modulated by dynamic fog
    float maxFogCap = min(1.0, GROUND_FOG_STRENGTH + GROUND_FOG_STRENGTH * isEyeInWater);
    applyDynamicFogModifiers(totalFogDensity, verticalFogDensity, maxFogCap);
    float baseFog = min(1.0, getAtmosphericFog(nEyePlayerPosY, max(0.0, worldPosY), viewDist, totalFogDensity, verticalFogDensity) * maxFogCap);

    #if WORLD_ID == 1 && defined END_BOSS_FOG
        baseFog = max(baseFog, getEndBossFogAmount(viewDist, worldPosY));
    #endif

    #if WORLD_ID == 0 && defined PALE_GARDEN_FOG
        baseFog = max(baseFog, getPaleGardenFogAmount(viewDist, worldPosY));
    #endif

    return baseFog;
}

float getFogEffectFactor(in float viewDist){
    // Blindness fog
    return exp2(-viewDist * effectFactor);
}