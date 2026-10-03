#ifndef METEOR_SHOWERS_GLSL
#define METEOR_SHOWERS_GLSL

// =================================================================================================
// Procedural Meteor Shower Simulation System for Super Duper Vanilla
// Features dynamic activity waves, variable sizes/lifetimes, pixel-aligned heads and crisp fading tails.
// =================================================================================================

#ifndef METEOR_RARITY
    #define METEOR_RARITY 2
#endif
#ifndef METEOR_SKY_COVERAGE
    #define METEOR_SKY_COVERAGE 0
#endif
#ifndef METEOR_SPEED
    #define METEOR_SPEED 1.00
#endif
#ifndef METEOR_TAIL_LENGTH
    #define METEOR_TAIL_LENGTH 1.00
#endif
#ifndef METEOR_SIZE
    #define METEOR_SIZE 1.00
#endif
#ifndef METEOR_TRAIL_FADE
    #define METEOR_TRAIL_FADE 1.00
#endif
#ifndef METEOR_COLOR_PROFILE
    #define METEOR_COLOR_PROFILE 0
#endif
#ifndef METEOR_WAVE_VARIATION
    #define METEOR_WAVE_VARIATION 1
#endif
#ifndef METEOR_RADIANT_SPREAD
    #define METEOR_RADIANT_SPREAD 0.08
#endif
#ifndef METEOR_RADIANT_DIRECTION
    #define METEOR_RADIANT_DIRECTION 0
#endif

#if !defined(PATCHED_SHADER) && !defined(VOXY_SHADING)
#ifndef WORLD_DAY_DECLARED
    #define WORLD_DAY_DECLARED
    uniform int worldDay;
#endif
#ifndef MOON_PHASE_DECLARED
    #define MOON_PHASE_DECLARED
    uniform int moonPhase;
#endif
#endif

float meteorHash12(in vec2 p){
    vec3 p3 = fract(vec3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

vec3 meteorHash32(in vec2 p){
    vec3 p3 = fract(vec3(p.xyx) * vec3(0.1031, 0.1030, 0.0973));
    p3 += dot(p3, p3.yxz + 33.33);
    return fract((p3.xxy + p3.yzz) * p3.zyx);
}

float getMeteorShowerRate(in float time){
    #if METEOR_RARITY == 1
        float dSeed = fract(sin(float(worldDay + 101) * 127.1 + 311.7) * 43758.5453);
        if(dSeed >= 0.45) return 0.0;
        float nightIntensity = mix(0.75, 1.25, dSeed / 0.45);
    #elif METEOR_RARITY == 2
        float dSeed = fract(sin(float(worldDay + 101) * 127.1 + 311.7) * 43758.5453);
        if(dSeed >= 0.25) return 0.0;
        float nightIntensity = mix(0.75, 1.25, dSeed / 0.25);
    #elif METEOR_RARITY == 3
        float dSeed = fract(sin(float(worldDay + 101) * 127.1 + 311.7) * 43758.5453);
        if(dSeed >= 0.12) return 0.0;
        float nightIntensity = mix(0.75, 1.25, dSeed / 0.12);
    #elif METEOR_RARITY == 4
        float dSeed = fract(sin(float(worldDay + 101) * 127.1 + 311.7) * 43758.5453);
        if(dSeed >= 0.06) return 0.0;
        float nightIntensity = mix(0.75, 1.25, dSeed / 0.06);
    #elif METEOR_RARITY == 5
        if(moonPhase != 4) return 0.0;
        float nightIntensity = 1.15;
    #else
        float nightIntensity = 1.00;
    #endif

    #if METEOR_WAVE_VARIATION == 1
        float showerWave = 0.50 + 0.32 * sin(time * 0.038) + 0.20 * sin(time * 0.021 + 1.9);
    #else
        float showerWave = 0.75;
    #endif

    #ifdef METEOR_SHOWER_STRENGTH
        return saturate(showerWave * nightIntensity * METEOR_SHOWER_STRENGTH);
    #else
        return saturate(showerWave * nightIntensity);
    #endif
}

void getMeteorPalette(in float pSeed, in float hueRand, in float s, in float sizeParam, in float headShape, in float headLum, in float tailLum, in float angDist, in float headLife, out vec3 headCol, out vec3 tailCol, out vec3 haloCol){
    vec3 headBaseCol;
    vec3 cTip, cMid, cHead;

    #if METEOR_COLOR_PROFILE == 1
        headBaseCol = vec3(0.90, 0.72, 1.00); cHead = vec3(0.85, 0.35, 0.95); cMid = vec3(0.55, 0.18, 0.90); cTip = vec3(0.28, 0.08, 0.65);
    #elif METEOR_COLOR_PROFILE == 2
        headBaseCol = vec3(0.70, 1.00, 0.85); cHead = vec3(0.25, 0.95, 0.60); cMid = vec3(0.12, 0.75, 0.45); cTip = vec3(0.05, 0.38, 0.40);
    #elif METEOR_COLOR_PROFILE == 3
        headBaseCol = vec3(1.00, 0.95, 0.75); cHead = vec3(1.00, 0.75, 0.25); cMid = vec3(0.98, 0.45, 0.12); cTip = vec3(0.75, 0.15, 0.05);
    #elif METEOR_COLOR_PROFILE == 4
        headBaseCol = vec3(1.00, 1.00, 1.00); cHead = vec3(0.92, 0.96, 1.00); cMid = vec3(0.80, 0.86, 0.95); cTip = vec3(0.55, 0.62, 0.75);
    #elif METEOR_COLOR_PROFILE == 5
        if(pSeed < 0.20){
            headBaseCol = vec3(0.55, 0.88, 1.00); cHead = vec3(0.42, 0.92, 1.00); cMid = vec3(0.18, 0.58, 1.00); cTip = vec3(0.10, 0.28, 0.90);
        } else if(pSeed < 0.40){
            headBaseCol = vec3(0.90, 0.72, 1.00); cHead = vec3(0.85, 0.35, 0.95); cMid = vec3(0.55, 0.18, 0.90); cTip = vec3(0.28, 0.08, 0.65);
        } else if(pSeed < 0.60){
            headBaseCol = vec3(0.70, 1.00, 0.85); cHead = vec3(0.25, 0.95, 0.60); cMid = vec3(0.12, 0.75, 0.45); cTip = vec3(0.05, 0.38, 0.40);
        } else if(pSeed < 0.80){
            headBaseCol = vec3(1.00, 0.95, 0.75); cHead = vec3(1.00, 0.75, 0.25); cMid = vec3(0.98, 0.45, 0.12); cTip = vec3(0.75, 0.15, 0.05);
        } else {
            headBaseCol = vec3(1.00, 1.00, 1.00); cHead = vec3(0.92, 0.96, 1.00); cMid = vec3(0.80, 0.86, 0.95); cTip = vec3(0.55, 0.62, 0.75);
        }
    #else
        headBaseCol = vec3(0.55, 0.88, 1.00); cHead = vec3(0.42, 0.92, 1.00); cMid = vec3(0.18, 0.58, 1.00); cTip = vec3(0.10, 0.28, 0.90);
    #endif

    vec3 headColor = mix(headBaseCol, vec3(1.00), headShape * 0.85);
    headCol = headColor * headLum;

    vec3 tailColor = mix(cTip, mix(cMid, cHead, s), mix(sqrt(s), s, 0.30));
    float hueOffset = (hueRand - 0.5) * 0.20;
    tailColor = saturate(tailColor + vec3(-hueOffset * 0.4, hueOffset * 0.2, hueOffset * 0.6));
    tailCol = tailColor * tailLum;

    haloCol = vec3(0.0);
    if(sizeParam > 0.60){
        float halo = exp(-angDist * 85.0) * (sizeParam - 0.60) * 1.6 * headLife;
        haloCol = cHead * (halo * 1.5);
    }
}

#if METEOR_RADIANT_DIRECTION == 5
    #ifndef SHADOW_MODEL_VIEW_DECLARED
        #define SHADOW_MODEL_VIEW_DECLARED
        uniform mat4 shadowModelView;
    #endif
#endif

vec3 renderMeteorStreak(
    in vec3 dir, in vec3 R_meteor, in vec3 uPhi_ortho, in vec3 N_plane,
    in float thetaHead, in float thetaTail, in float progress, in float sizeParam,
    in vec3 h1, in vec3 h2, in float elevFade
){
    float pDist = dot(dir, N_plane);
    vec3 dirProj = dir - N_plane * pDist;
    float projLen = length(dirProj);
    if(projLen < 0.0001) return vec3(0.0);
    dirProj /= projLen;

    float cosTh = dot(dirProj, R_meteor);
    float sinTh = dot(dirProj, uPhi_ortho);
    float thetaRay = atan(sinTh, cosTh);
    if(thetaRay < -0.2) thetaRay += 6.2831853;

    float angDist = sqrt(max(0.0, pDist * pDist + (thetaRay < thetaTail ? (thetaTail - thetaRay) * (thetaTail - thetaRay) : (thetaRay > thetaHead ? (thetaRay - thetaHead) * (thetaRay - thetaHead) : 0.0))));

    float segLen = max(0.0001, thetaHead - thetaTail);
    float s = saturate((thetaRay - thetaTail) / segLen);

    vec3 H = R_meteor * cos(thetaHead) + uPhi_ortho * sin(thetaHead);
    vec3 Dhead = -R_meteor * sin(thetaHead) + uPhi_ortho * cos(thetaHead);
    vec3 Bhead = cross(H, Dhead);
    vec3 deltaH = dir - H;
    float uHead = dot(deltaH, Bhead);
    float vHead = dot(deltaH, Dhead);
    float boxHeadDist = max(abs(uHead), abs(vHead));

    if(SUN_MOON_ROUNDNESS > 0.0){
        boxHeadDist = mix(boxHeadDist, length(deltaH), SUN_MOON_ROUNDNESS);
    }

    float headRadius = mix(0.0011, 0.0021, sizeParam) * METEOR_SIZE * METEOR_HEAD_SIZE;
    float headCore = saturate(1.0 - boxHeadDist / headRadius);
    headCore = headCore * headCore;
    float headGlow = saturate(1.0 - boxHeadDist / (headRadius * 1.45));
    headGlow = headGlow * headGlow * headGlow;
    float headShape = mix(headCore, headGlow, 0.35);

    float headLife = smoothstep(0.0, 0.08, progress) * smoothstep(0.82, 0.65, progress);
    float headLum = headShape * headLife * mix(6.0, 10.5, sizeParam);

    float baseTailRadius = mix(0.00070, 0.00135, sizeParam) * METEOR_SIZE;
    float localTailRadius = baseTailRadius * mix(0.48, 1.00, s);
    float transCore = saturate(1.0 - angDist / localTailRadius);
    transCore = transCore * transCore;
    float transGlow = exp(-angDist * angDist / (2.0 * localTailRadius * localTailRadius));
    float transShape = mix(transGlow * 0.22, transCore, 0.78);

    float longFade = (METEOR_TRAIL_FADE == 1.0) ? (s * sqrt(s)) : pow(max(0.0001, s), 1.45 * METEOR_TRAIL_FADE);
    float tailLife = smoothstep(0.0, 0.06, progress) * smoothstep(1.0, 0.72, progress);
    float tailLum = transShape * longFade * tailLife * mix(2.8, 5.2, sizeParam);

    vec3 headCol, tailCol, haloCol;
    getMeteorPalette(fract(h2.z * 5.0), h2.z, s, sizeParam, headShape, headLum, tailLum, angDist, headLife, headCol, tailCol, haloCol);

    float flare = sin(progress * 40.0 + h1.x * 25.0) * 0.12 + 0.88;
    return (headCol * flare + tailCol + haloCol) * elevFade;
}

vec3 getProceduralMeteorShowers(in vec3 viewPos, in vec3 skyPos, in float time){
    #if WORLD_SUN_MOON == 1
        if(skyPos.z < -0.7 && getSunMoonDist(skyPos.xy, WORLD_SUN_MOON_SIZE * (-skyPos.z)) <= WORLD_SUN_MOON_SIZE * (-skyPos.z)){
            return vec3(0.0);
        }
    #endif

    float showerRate = getMeteorShowerRate(time);
    if(showerRate <= 0.001) return vec3(0.0);

    #if METEOR_RADIANT_DIRECTION == 1
        vec3 dir = viewPos; const vec3 RADIANT_BASE = vec3(-1.0, 1.25, -1.0);
    #elif METEOR_RADIANT_DIRECTION == 2
        vec3 dir = viewPos; const vec3 RADIANT_BASE = vec3(1.0, 1.25, 1.0);
    #elif METEOR_RADIANT_DIRECTION == 3
        vec3 dir = viewPos; const vec3 RADIANT_BASE = vec3(-1.0, 1.25, 1.0);
    #elif METEOR_RADIANT_DIRECTION == 4
        vec3 dir = viewPos; const vec3 RADIANT_BASE = vec3(0.0, 1.0, 0.0);
    #elif METEOR_RADIANT_DIRECTION == 5
        vec3 dir = viewPos; vec3 RADIANT_BASE = vec3(0.42, 0.68, -0.60) * mat3(shadowModelView);
    #else
        vec3 dir = viewPos; const vec3 RADIANT_BASE = vec3(1.0, 1.25, -1.0);
    #endif

    vec3 R = fastNormalize(RADIANT_BASE);
    if(R.y <= 0.05) return vec3(0.0);
    vec3 rUp = abs(R.y) < 0.95 ? vec3(0.0, 1.0, 0.0) : vec3(0.0, 0.0, 1.0);
    vec3 rX = fastNormalize(cross(rUp, R));
    vec3 rY = cross(R, rX);

    vec3 totalMeteors = vec3(0.0);
    const int NUM_SLOTS = 10;

    for(int i = 0; i < NUM_SLOTS; i++){
        float slotF = float(i);
        float period = 1.30 + meteorHash12(vec2(slotF, 47.19)) * 1.55;
        float scaledTime = time * METEOR_SPEED;
        float progress = fract((scaledTime + slotF * 0.73) / period);
        float cycleIndex = floor((scaledTime + slotF * 0.73) / period);

        vec3 h1 = meteorHash32(vec2(slotF * 13.71, cycleIndex));
        vec3 h2 = meteorHash32(vec2(slotF * 31.17 + 5.9, cycleIndex + 17.3));

        float slotThreshold = (slotF + 0.35) / float(NUM_SLOTS);
        if(showerRate < slotThreshold && h1.z > showerRate) continue;

        // Radiant direction for this meteor (spread around the origin point)
        #if METEOR_SKY_COVERAGE == 1
            float phi = 1.5707963 + (h1.x * 2.0 - 1.0) * 0.85;
        #elif METEOR_SKY_COVERAGE == 2
            float phi = fract(slotF * 0.6180339887 + h1.x * 0.30) * 6.2831853;
        #else
            float phi = fract(slotF * 0.6180339887 + h1.x * 0.30) * 6.2831853;
        #endif

        vec3 uPhi = rX * cos(phi) + rY * sin(phi);
        vec3 R_meteor = fastNormalize(R + uPhi * (h1.y * METEOR_RADIANT_SPREAD));

        vec3 N_plane = fastNormalize(cross(R_meteor, uPhi));
        vec3 uPhi_ortho = cross(N_plane, R_meteor);

        float theta_horizon = atan(R_meteor.y, -uPhi_ortho.y);
        if(theta_horizon < 0.15) continue;
        float safeArc = theta_horizon - 0.08;

        #if METEOR_SKY_COVERAGE == 2
            float streakSpan = min(safeArc * 0.50, mix(0.15, 0.35, h2.y) * METEOR_TAIL_LENGTH);
            float maxStart = max(0.02, min(safeArc - streakSpan, 0.40));
        #else
            float streakSpan = min(safeArc * 0.60, mix(0.22, 0.55, h2.y) * METEOR_TAIL_LENGTH);
            float maxStart = max(0.02, safeArc - streakSpan);
        #endif

        float startAngle = mix(0.02, maxStart, h2.x);
        float thetaHead = startAngle + streakSpan * progress;
        float tailLen = streakSpan * mix(0.25, 0.42, h2.z) * METEOR_TAIL_LENGTH;
        float thetaTail = max(startAngle, thetaHead - tailLen);

        vec3 H = R_meteor * cos(thetaHead) + uPhi_ortho * sin(thetaHead);
        float elevFade = saturate((H.y - 0.04) * 10.0);
        if(elevFade <= 0.0) continue;

        totalMeteors += renderMeteorStreak(dir, R_meteor, uPhi_ortho, N_plane, thetaHead, thetaTail, progress, h1.z, h1, h2, elevFade);
    }

    return totalMeteors;
}

#endif // METEOR_SHOWERS_GLSL
