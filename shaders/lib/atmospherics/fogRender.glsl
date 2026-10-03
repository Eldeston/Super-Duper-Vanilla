#ifndef IS_PALE_GARDEN_DECLARED
    #define IS_PALE_GARDEN_DECLARED
    uniform float isPaleGarden;
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
vec3 getPaleGardenFogColor(in vec3 nEyePlayerPos){
    #ifndef FORCE_DISABLE_DAY_CYCLE
        float dCycle = dayCycle;
    #else
        float dCycle = 1.0;
    #endif

    // Pale light silvery gray base
    vec3 paleDay = toLinear(vec3(0.76, 0.77, 0.79));
    vec3 paleTwilight = toLinear(vec3(0.44, 0.44, 0.47));
    vec3 paleNight = toLinear(vec3(0.12, 0.13, 0.16));
    vec3 paleBase = lerp(paleNight, paleTwilight, paleDay, dCycle);

    // Subtle blend with vanilla biome fog color for natural integration
    float dayBrightness = 0.35 + 0.65 * saturate(dCycle * 0.5);
    vec3 vanillaBiomeFog = toLinear(fogColor) * (1.15 * dayBrightness);
    vec3 col = mix(paleBase, vanillaBiomeFog, 0.30);

    #ifndef FORCE_DISABLE_WEATHER
        col = mix(col, toLinear(fogColor), weatherFade * 0.4);
    #endif

    // Soft forward sun glow through the mist during the day
    vec3 sunDir = vec3(shadowModelView[0].z, shadowModelView[1].z, shadowModelView[2].z);
    float sunGlow = pow(saturate(dot(nEyePlayerPos, sunDir) * 0.5 + 0.5), 4.0);
    col += toLinear(vec3(0.12, 0.10, 0.08)) * (sunGlow * saturate(dCycle - 1.0));

    return col;
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

float getFogFactor(in float viewDist, in float nEyePlayerPosY, in float worldPosY){
    #ifdef FORCE_DISABLE_WEATHER
        float verticalFogDensity = isEyeInWater == 0 ? FOG_VERTICAL_DENSITY : FOG_VERTICAL_DENSITY * 0.2;
        float totalFogDensity = isEyeInWater == 0 ? FOG_TOTAL_DENSITY : FOG_TOTAL_DENSITY * TAU;
    #else
        // Gentle atmospheric rain haze instead of blinding opaque fog wall
        float verticalFogDensity = isEyeInWater == 0 ? FOG_VERTICAL_DENSITY * (1.0 - weatherFade * 0.20) : FOG_VERTICAL_DENSITY * 0.2;
        float totalFogDensity = isEyeInWater == 0 ? FOG_TOTAL_DENSITY * (1.0 + weatherFade * 0.45) : FOG_TOTAL_DENSITY * TAU;
    #endif

    // Return fog, capped with ground fog strength
    float baseFog = min(1.0, getAtmosphericFog(nEyePlayerPosY, max(0.0, worldPosY), viewDist, totalFogDensity, verticalFogDensity) * min(1.0, GROUND_FOG_STRENGTH + GROUND_FOG_STRENGTH * isEyeInWater));

    #if WORLD_ID == 1 && defined END_BOSS_FOG
        if(isEyeInWater == 0 && END_BOSS_FOG > 0.0 && fogEnd <= 100.0 && (fogStart / max(fogEnd, 0.001)) < 0.60 && effectFactor < 0.01){
            float bStart = max(0.0, fogStart * (0.8 / max(END_BOSS_FOG, 0.5)));
            float bEnd = max(bStart + 25.0, fogEnd * (1.1 / pow(END_BOSS_FOG, 0.35)));
            float bDistProgress = saturate((viewDist - bStart) / (bEnd - bStart));
            float bossDensity = 1.0 - exp2(-pow(bDistProgress, 1.25) * (4.2 * END_BOSS_FOG));
            float heightFade = saturate(1.0 - max(0.0, worldPosY - 80.0) * 0.012);
            float bossFogAmount = bossDensity * mix(0.70, 1.0, heightFade);
            baseFog = max(baseFog, bossFogAmount);
        }
    #endif

    #if WORLD_ID == 0 && defined PALE_GARDEN_FOG
        if(isEyeInWater == 0 && PALE_GARDEN_FOG > 0.0 && isPaleGarden > 0.001 && effectFactor < 0.01){
            float pgStart = 12.0 / max(PALE_GARDEN_FOG, 0.5);
            float pgEnd = max(pgStart + 25.0, 70.0 / pow(PALE_GARDEN_FOG, 0.4));
            float pgDistProgress = saturate((viewDist - pgStart) / (pgEnd - pgStart));
            float pgDensity = 1.0 - exp2(-pow(pgDistProgress, 1.15) * (4.2 * PALE_GARDEN_FOG));
            float heightFade = saturate(1.0 - max(0.0, worldPosY - 105.0) * 0.016);
            float paleFogAmount = pgDensity * isPaleGarden * mix(0.70, 1.0, heightFade);
            baseFog = max(baseFog, paleFogAmount);
        }
    #endif

    return baseFog;
}

float getFogEffectFactor(in float viewDist){
    // Blindness fog
    return exp2(-viewDist * effectFactor);
}