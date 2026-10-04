#ifndef LIGHTNING_GLSL
#define LIGHTNING_GLSL

/*
================================ /// Super Duper Vanilla /// ================================

    Procedural Lightning, Dynamic Flashes, and Intra-Cloud Illumination System
    - Shortened, punchy, realistic lightning flashes with instant attack and rapid exponential decay
    - Subtle optional atmospheric strobe effect occurring on ~38% of discharges (rapid multi-stroke re-strikes)
    - Cloud-to-cloud atmospheric visual lightning discharges:
        * 100% faithful to vanilla Minecraft geometric segmented line aesthetic with sharp polygonal kinks
        * Rich hierarchical branching (main trunk, primary forks, secondary tendrils)
        * Zero audio noise/sound (pure visual shader atmosphere) and no fuzzy texture noise blobs
    - Dynamic internal cloud flashing glows that light up clouds from within with spatial scattering
    - Comprehensive photosensitivity / epilepsy safety protection:
        * EPILEPSY_SAFETY setting completely disables all flashing and strobing lights in the shader

================================ /// Super Duper Vanilla /// ================================
*/

#ifndef PI
    #define PI 3.14159265
#endif
#ifndef TAU
    #define TAU 6.28318531
#endif

#ifndef LIGHTNING_FLASH
    #define LIGHTNING_FLASH 1
#endif
#ifndef CLOUD_LIGHTNING_BRANCHES
    #define CLOUD_LIGHTNING_BRANCHES 2
#endif
#ifndef CLOUD_LIGHTNING_GLOW
    #define CLOUD_LIGHTNING_GLOW 1.00
#endif
#ifndef CLOUD_LIGHTNING_FREQUENCY
    #define CLOUD_LIGHTNING_FREQUENCY 1.00
#endif

#ifndef LIGHTNING_BOLT_POS_DECLARED
    #define LIGHTNING_BOLT_POS_DECLARED
    uniform vec4 lightningBoltPosition;
#endif

// Fast, non-repeating deterministic hash functions
float lightningHash11(in float p){
    p = fract(p * 0.1031);
    p *= p + 33.33;
    p *= p + p;
    return fract(p);
}

vec2 lightningHash21(in float p){
    vec3 p3 = fract(vec3(p) * vec3(0.1031, 0.1030, 0.0973));
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.xx + p3.yz) * p3.zy);
}

// Distance from 2D point p to straight line segment ab
void addLightningSegment(in vec2 p, in vec2 a, in vec2 b, inout float minDist){
    vec2 ba = b - a;
    vec2 pa = p - a;
    float h = clamp(dot(pa, ba) / max(dot(ba, ba), 0.000001), 0.0, 1.0);
    minDist = min(minDist, length(pa - ba * h));
}

#if WORLD_ID == 0 && !defined FORCE_DISABLE_WEATHER
    #ifndef THUNDER_STRENGTH_DECLARED
        #define THUNDER_STRENGTH_DECLARED
        uniform float thunderStrength;
    #endif
#endif

// Strike state information struct
struct LightningStrikeState {
    bool isActive;
    float flash;
    vec3 dir;
    float seed;
    bool isVisibleBolt;
};

// Evaluates cloud-to-cloud strike timing, location, flash, and branching seed
LightningStrikeState getCloudLightningState(){
    LightningStrikeState state;
    state.isActive = false;
    state.flash = 0.0;
    state.dir = vec3(0.0, 1.0, 0.0);
    state.seed = 0.0;
    state.isVisibleBolt = false;

    #ifdef EPILEPSY_SAFETY
        return state;
    #endif

    #ifndef CLOUD_LIGHTNING
        return state;
    #endif

    #if WORLD_ID != 0 || defined FORCE_DISABLE_WEATHER
        return state;
    #else
        float stormFade = clamp(max(weatherFade, thunderStrength), 0.0, 1.0);
        float stormFactor = saturate(rainStrength * 2.2 + stormFade * 0.4);
        if(stormFactor < 0.04) return state;

        float period = 7.5 / max(float(CLOUD_LIGHTNING_FREQUENCY), 0.1);
        float cycle = floor(fragmentFrameTime / period);
        float cycleHash = lightningHash11(cycle * 31.71 + 7.13);

        // Weather activity gating: lighter rain produces fewer strikes; heavy storms produce more
        if(cycleHash > stormFactor * 1.25) return state;

        float strikeStart = cycle * period + cycleHash * (period - 1.2);
        float dt = fragmentFrameTime - strikeStart;

        // Discharges last ~0.35s in total
        if(dt < 0.0 || dt >= 0.35) return state;

        state.isActive = true;
        state.seed = cycle * 127.19 + 43.17;

        // Strike direction in sky (azimuth across 360°, elevation between 16° and 60° in cloud deck)
        float az = lightningHash11(state.seed * 3.31 + 1.7) * TAU;
        float el = mix(0.28, 0.85, lightningHash11(state.seed * 5.17 + 9.3));
        float cosEl = cos(el);
        state.dir = vec3(cos(az) * cosEl, sin(el), sin(az) * cosEl);

        // Flash & Strobe calculation
        #if LIGHTNING_FLASH == 0
            state.flash = 0.0;
        #else
            #ifdef LIGHTNING_STROBE
                // Strobe effect occurs on ~38% of discharges
                bool hasStrobe = (lightningHash11(state.seed * 11.3 + 2.7) < 0.38);
            #else
                bool hasStrobe = false;
            #endif

            if(hasStrobe){
                // Rapid multi-stroke re-strikes (subtle natural atmospheric flutter)
                float p0 = exp(-dt * 20.0);
                float dt1 = dt - 0.065;
                float p1 = dt1 > 0.0 ? exp(-dt1 * 26.0) * 0.60 : 0.0;
                float dt2 = dt - 0.130;
                float p2 = dt2 > 0.0 ? exp(-dt2 * 32.0) * 0.35 : 0.0;
                state.flash = clamp(p0 + p1 + p2, 0.0, 1.0);
            } else {
                // Clean, punchy short flash with rapid exponential decay
                #if LIGHTNING_FLASH == 2
                    // Smooth fade
                    state.flash = exp(-dt * 9.0);
                #else
                    // Realistic short flash (decay in ~150ms)
                    state.flash = exp(-dt * 18.0);
                #endif
            }
        #endif

        state.isVisibleBolt = (lightningHash11(state.seed * 7.73 + 1.1) > 0.30);

        return state;
    #endif
}

// Direction vector towards active lightning discharge in player space
vec3 getLightningDischargeDir(){
    #ifndef EPILEPSY_SAFETY
        #if WORLD_ID == 0
            // If a vanilla ground bolt is present, use its player-space direction
            if(lightningBoltPosition.w > 0.001){
                vec3 groundBoltEye = lightningBoltPosition.xyz;
                if(lengthSquared(groundBoltEye) > 0.001){
                    return fastNormalize(mat3(gbufferModelViewInverse) * groundBoltEye);
                }
            }

            LightningStrikeState ccState = getCloudLightningState();
            if(ccState.isActive){
                return ccState.dir;
            }
        #endif
    #endif

    return vec3(0.0, 1.0, 0.0);
}

// Combined effective lightning flash intensity across ground strikes and cloud-to-cloud strikes
float getLightningFlashIntensity(){
    #ifdef EPILEPSY_SAFETY
        return 0.0;
    #endif

    #if LIGHTNING_FLASH == 0
        return 0.0;
    #endif

    float flash = 0.0;

    // Ground strike flash (shortened by smooth in shaders.properties)
    flash = max(flash, lightningFlash);

    // Strobe modulation on ground strike if active
    #ifdef LIGHTNING_STROBE
        if(lightningBoltPosition.w > 0.001 && flash > 0.01){
            float groundSeed = floor(lightningBoltPosition.x * 0.2) * 31.17 + floor(lightningBoltPosition.z * 0.2) * 73.53;
            if(lightningHash11(groundSeed) < 0.38){
                // Apply subtle multi-stroke restrike modulation to ground strike
                float gFlicker = sin(fragmentFrameTime * 48.0 + groundSeed) * 0.25;
                flash = saturate(flash * (1.0 + gFlicker));
            }
        }
    #endif

    // Cloud-to-cloud flash
    LightningStrikeState ccState = getCloudLightningState();
    if(ccState.isActive){
        flash = max(flash, ccState.flash);
    }

    return saturate(flash);
}

void evalLightningBranches(
    in vec2 p, in float alpha, in float boltLen, in float strikeSeed,
    in vec2 trunkPts[11], inout float dBranch, inout float dTendril
){
    float b1Angle = alpha + 0.75, lenB1 = boltLen * 0.42;
    vec2 dirB1 = vec2(cos(b1Angle), sin(b1Angle)), perpB1 = vec2(-dirB1.y, dirB1.x), b1Pts[5];
    b1Pts[0] = trunkPts[3]; float kinkB1 = 0.0;
    for(int i = 1; i <= 4; ++i){
        float fi = float(i), h = lightningHash11(strikeSeed * 2.31 + fi * 13.17);
        kinkB1 += (h - 0.5) * (lenB1 * 0.26);
        b1Pts[i] = trunkPts[3] + dirB1 * (fi * 0.25 * lenB1) + perpB1 * kinkB1;
        addLightningSegment(p, b1Pts[i - 1], b1Pts[i], dBranch);
    }

    float b2Angle = alpha - 0.70, lenB2 = boltLen * 0.46;
    vec2 dirB2 = vec2(cos(b2Angle), sin(b2Angle)), perpB2 = vec2(-dirB2.y, dirB2.x), b2Pts[5];
    b2Pts[0] = trunkPts[6]; float kinkB2 = 0.0;
    for(int i = 1; i <= 4; ++i){
        float fi = float(i), h = lightningHash11(strikeSeed * 4.73 + fi * 19.41);
        kinkB2 += (h - 0.5) * (lenB2 * 0.26);
        b2Pts[i] = trunkPts[6] + dirB2 * (fi * 0.25 * lenB2) + perpB2 * kinkB2;
        addLightningSegment(p, b2Pts[i - 1], b2Pts[i], dBranch);
    }

    float b3Angle = alpha + 0.65, lenB3 = boltLen * 0.35;
    vec2 dirB3 = vec2(cos(b3Angle), sin(b3Angle)), perpB3 = vec2(-dirB3.y, dirB3.x), b3Pts[4];
    b3Pts[0] = trunkPts[8]; float kinkB3 = 0.0;
    for(int i = 1; i <= 3; ++i){
        float fi = float(i), h = lightningHash11(strikeSeed * 6.19 + fi * 23.83);
        kinkB3 += (h - 0.5) * (lenB3 * 0.33);
        b3Pts[i] = trunkPts[8] + dirB3 * (fi * 0.33 * lenB3) + perpB3 * kinkB3;
        addLightningSegment(p, b3Pts[i - 1], b3Pts[i], dBranch);
    }

    #if CLOUD_LIGHTNING_BRANCHES >= 2
        vec2 dirT1 = vec2(cos(b1Angle - 0.70), sin(b1Angle - 0.70)), perpT1 = vec2(-dirT1.y, dirT1.x);
        float lenT1 = lenB1 * 0.55;
        vec2 t1_1 = b1Pts[2] + dirT1 * (0.5 * lenT1) + perpT1 * ((lightningHash11(strikeSeed + 71.1) - 0.5) * 0.08);
        vec2 t1_2 = b1Pts[2] + dirT1 * (1.0 * lenT1) + perpT1 * ((lightningHash11(strikeSeed + 73.3) - 0.5) * 0.12);
        addLightningSegment(p, b1Pts[2], t1_1, dTendril); addLightningSegment(p, t1_1, t1_2, dTendril);

        vec2 dirT2 = vec2(cos(b2Angle + 0.75), sin(b2Angle + 0.75)), perpT2 = vec2(-dirT2.y, dirT2.x);
        float lenT2 = lenB2 * 0.50;
        vec2 t2_1 = b2Pts[2] + dirT2 * (0.5 * lenT2) + perpT2 * ((lightningHash11(strikeSeed + 81.1) - 0.5) * 0.08);
        vec2 t2_2 = b2Pts[2] + dirT2 * (1.0 * lenT2) + perpT2 * ((lightningHash11(strikeSeed + 83.3) - 0.5) * 0.12);
        addLightningSegment(p, b2Pts[2], t2_1, dTendril); addLightningSegment(p, t2_1, t2_2, dTendril);

        vec2 dirT3 = vec2(cos(alpha - 0.95), sin(alpha - 0.95)), perpT3 = vec2(-dirT3.y, dirT3.x);
        float lenT3 = boltLen * 0.25;
        vec2 t3_1 = trunkPts[4] + dirT3 * (0.5 * lenT3) + perpT3 * ((lightningHash11(strikeSeed + 91.1) - 0.5) * 0.06);
        vec2 t3_2 = trunkPts[4] + dirT3 * (1.0 * lenT3) + perpT3 * ((lightningHash11(strikeSeed + 93.3) - 0.5) * 0.09);
        addLightningSegment(p, trunkPts[4], t3_1, dTendril); addLightningSegment(p, t3_1, t3_2, dTendril);
    #endif

    #if CLOUD_LIGHTNING_BRANCHES >= 3
        vec2 dirT4 = vec2(cos(b1Angle + 0.60), sin(b1Angle + 0.60)), perpT4 = vec2(-dirT4.y, dirT4.x);
        float lenT4 = lenB1 * 0.40;
        vec2 t4_1 = b1Pts[3] + dirT4 * (0.5 * lenT4) + perpT4 * ((lightningHash11(strikeSeed + 101.1) - 0.5) * 0.05);
        vec2 t4_2 = b1Pts[3] + dirT4 * (1.0 * lenT4) + perpT4 * ((lightningHash11(strikeSeed + 103.3) - 0.5) * 0.08);
        addLightningSegment(p, b1Pts[3], t4_1, dTendril); addLightningSegment(p, t4_1, t4_2, dTendril);

        vec2 dirT5 = vec2(cos(b2Angle - 0.60), sin(b2Angle - 0.60)), perpT5 = vec2(-dirT5.y, dirT5.x);
        float lenT5 = lenB2 * 0.40;
        vec2 t5_1 = b2Pts[3] + dirT5 * (0.5 * lenT5) + perpT5 * ((lightningHash11(strikeSeed + 111.1) - 0.5) * 0.05);
        vec2 t5_2 = b2Pts[3] + dirT5 * (1.0 * lenT5) + perpT5 * ((lightningHash11(strikeSeed + 113.3) - 0.5) * 0.08);
        addLightningSegment(p, b2Pts[3], t5_1, dTendril); addLightningSegment(p, t5_1, t5_2, dTendril);
    #endif
}

// Geometric vanilla-faithful cloud-to-cloud lightning bolt rendering
// Uses crisp polygon straight line segments with sharp kinks, hierarchical branching, zero audio noise/sound
vec3 getCloudLightningRender(in vec3 nEyePlayerPos){
    #ifdef EPILEPSY_SAFETY
        return vec3(0.0);
    #endif

    #ifndef CLOUD_LIGHTNING
        return vec3(0.0);
    #endif

    #if WORLD_ID != 0
        return vec3(0.0);
    #endif

    LightningStrikeState state = getCloudLightningState();
    if(!state.isActive || !state.isVisibleBolt || state.flash <= 0.002) return vec3(0.0);

    // Tangent-space gnomonic projection centered at the strike direction
    float dotP = dot(nEyePlayerPos, state.dir);
    if(dotP < 0.55) return vec3(0.0);

    vec3 upRef = abs(state.dir.y) < 0.99 ? vec3(0.0, 1.0, 0.0) : vec3(0.0, 0.0, 1.0);
    vec3 tanX = fastNormalize(cross(upRef, state.dir));
    vec3 tanY = cross(state.dir, tanX);
    vec2 p = vec2(dot(nEyePlayerPos, tanX), dot(nEyePlayerPos, tanY)) / dotP;

    // Fast bounding circle check in tangent space (radius 0.40)
    if(lengthSquared(p) > 0.16) return vec3(0.0);

    float strikeSeed = state.seed;

    // Travel angle of the bolt in the cloud sheet
    float alpha = lightningHash11(strikeSeed * 11.23) * TAU;
    vec2 dir = vec2(cos(alpha), sin(alpha));
    vec2 perp = vec2(-dir.y, dir.x);

    float boltLen = mix(0.32, 0.48, lightningHash11(strikeSeed * 5.37));
    vec2 pStart = -dir * (boltLen * 0.5);

    // --- 1. Main Trunk (10 straight segments with sharp vanilla-style kinks) ---
    vec2 trunkPts[11];
    trunkPts[0] = pStart;
    float currentKink = 0.0;
    float dTrunk = 1000.0;

    for(int i = 1; i <= 10; ++i){
        float fi = float(i);
        float h = lightningHash11(strikeSeed + fi * 17.31);
        currentKink += (h - 0.5) * (boltLen * 0.22);
        trunkPts[i] = pStart + dir * (fi * 0.10 * boltLen) + perp * currentKink;
        addLightningSegment(p, trunkPts[i - 1], trunkPts[i], dTrunk);
    }

    // --- 2. Primary & Secondary Fork Branches ---
    float dBranch = 1000.0;
    float dTendril = 1000.0;
    evalLightningBranches(p, alpha, boltLen, strikeSeed, trunkPts, dBranch, dTendril);

    // Core thickness radii (polygonal line profiles faithful to vanilla)
    const float trunkRadius = 0.0035;
    const float branchRadius = 0.0022;
    const float tendrilRadius = 0.0013;

    float coreTrunk = saturate(1.0 - dTrunk / trunkRadius);
    float coreBranch = saturate(1.0 - dBranch / branchRadius);
    float coreTendril = saturate(1.0 - dTendril / tendrilRadius);

    float core = max(coreTrunk, max(coreBranch * 0.85, coreTendril * 0.70));
    // Crisp vanilla profile: sharp step with intense emissive core
    core = core * core * (3.0 - 2.0 * core);

    // Natural atmospheric electric corona / glow around the crisp geometric segments
    float aura = exp(-dTrunk * 45.0) * 0.85 + exp(-dBranch * 70.0) * 0.50 + exp(-dTendril * 95.0) * 0.30;

    // Emissive HDR lightning bolt
    vec3 boltCol = (vec3(1.0) * (core * 6.0) + vec3(0.65, 0.82, 1.0) * (aura * 2.4)) * state.flash;
    return boltCol;
}

// Internal flashing glow that illuminates clouds from within
// Lights up the cloud mass itself with internal light scattering and radial diffusion
vec3 getCloudInternalFlashGlow(in vec3 dir, in float cloudDensity){
    #ifdef EPILEPSY_SAFETY
        return vec3(0.0);
    #endif

    #if WORLD_ID != 0
        return vec3(0.0);
    #endif

    if(CLOUD_LIGHTNING_GLOW <= 0.001) return vec3(0.0);
    if(cloudDensity <= 0.001) return vec3(0.0);

    float flash = getLightningFlashIntensity();
    if(flash <= 0.002) return vec3(0.0);

    vec3 strikeDir = getLightningDischargeDir();
    float dotP = dot(dir, strikeDir);

    // Broad spatial diffusion across the cloud bank from the discharge origin
    float spatialGlow = exp(-(1.0 - dotP) * 2.8);

    // Internal cloud scattering: dense cloud volume traps and scatters light brightly from within
    float internalScatter = cloudDensity * (0.85 + cloudDensity * 1.35);

    vec3 glowColor = vec3(0.72, 0.85, 1.0);
    return glowColor * (flash * spatialGlow * internalScatter * (1.35 * CLOUD_LIGHTNING_GLOW));
}

#endif // LIGHTNING_GLSL
