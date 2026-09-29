#ifndef PI
    #define PI 3.14159265
#endif
#ifndef TAU
    #define TAU 6.28318531
#endif
#ifndef STAR_ROTATION
    #define STAR_ROTATION 0
#endif

#ifndef CELESTIAL_RENDER_GLSL
    #include "/lib/atmospherics/celestialRender.glsl"
#endif

float hash12(in vec2 p){
    vec3 p3 = fract(vec3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

vec3 hash32(in vec2 p){
    vec3 p3 = fract(vec3(p.xyx) * vec3(0.1031, 0.1030, 0.0973));
    p3 += dot(p3, p3.yxz + 33.33);
    return fract((p3.xxy + p3.yzz) * p3.zyx);
}

float periodicValueNoise(in vec2 p, in float periodX){
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    
    float iX0 = mod(i.x, periodX);
    float iX1 = mod(i.x + 1.0, periodX);
    
    float a = hash12(vec2(iX0, i.y));
    float b = hash12(vec2(iX1, i.y));
    float c = hash12(vec2(iX0, i.y + 1.0));
    float d = hash12(vec2(iX1, i.y + 1.0));
    
    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

// Orthonormal galactic coordinate basis (tilted 54.7 degrees from celestial pole)
const vec3 gCore = vec3( 0.70710678, -0.70710678,  0.0);
const vec3 gSide = vec3( 0.40824829,  0.40824829, -0.81649658);
const vec3 gPole = vec3( 0.57735027,  0.57735027,  0.57735027);

void getCelestialCubemap(in vec3 v, out vec2 faceUV, out float faceId){
    vec3 a = abs(v);
    float maxAxis = max(a.x, max(a.y, a.z));
    if(maxAxis == a.z){
        faceUV = v.xy / a.z;
        faceId = v.z > 0.0 ? 0.0 : 1.0;
    } else if(maxAxis == a.x){
        faceUV = v.yz / a.x;
        faceId = v.x > 0.0 ? 2.0 : 3.0;
    } else {
        faceUV = v.xz / a.y;
        faceId = v.y > 0.0 ? 4.0 : 5.0;
    }
}

// Procedural square background stars across the entire celestial sphere (cubemap projection)
vec3 getProceduralSquareStars(in vec3 v, in float time){
    // Occlude stars directly behind the moon disk
    #if WORLD_SUN_MOON == 1
        if(v.z < -0.7 && getSunMoonDist(v.xy, WORLD_SUN_MOON_SIZE * (-v.z)) <= WORLD_SUN_MOON_SIZE * (-v.z)) return vec3(0.0);
    #endif

    vec2 faceUV;
    float faceId;
    getCelestialCubemap(v, faceUV, faceId);
    
    // Balanced grid resolution (~100x100 per face for realistic star density and spacing)
    const float BG_STAR_GRID = 100.0;
    vec2 gridPos = (faceUV * 0.5 + 0.5) * BG_STAR_GRID;
    vec2 cell = floor(gridPos);
    vec2 fracPos = fract(gridPos) - 0.5;
    
    vec3 h = hash32(cell + faceId * 113.7);
    
    // Realistic astronomical distribution:
    // Star density naturally increases slightly toward the galactic plane
    float gLat = dot(v, gPole);
    float galBias = saturate(1.0 - abs(gLat) * 0.7);
    float starThreshold = 0.985 - galBias * 0.010;
    
    vec3 starOut = vec3(0.0);
    if(h.x > starThreshold){
        #ifndef MOON_PHASE_FACTOR
            #define MOON_PHASE_FACTOR 1.0
        #endif
        float moonIllum = MOON_PHASE_FACTOR;
        
        // Multi-tier stellar magnitude modulated by moon phase:
        // Constellation stars cut through bright moonlight, while faint stars are heavily washed out
        bool isConstellation = h.z > 0.93;
        float size;
        float magnitude;
        vec3 col;
        
        if(isConstellation){
            // Bright constellation beacons (Sirius, Vega, Rigel, Betelgeuse class)
            float rank = (h.z - 0.93) / 0.07;
            size = 0.25 + rank * 0.06;
            magnitude = (3.2 + pow(rank, 1.4) * 4.5) * mix(1.0, 0.80, moonIllum);
            
            // Astronomical stellar spectral colors for prominent constellation stars:
            // 0.00-0.35: Blue-white (O/B/A), 0.35-0.70: Pure white / pale gold (F/G), 0.70-1.00: Warm amber/orange (K/M)
            if(h.y < 0.35){
                col = mix(vec3(0.78, 0.88, 1.0), vec3(0.90, 0.95, 1.0), h.y / 0.35);
            } else if(h.y < 0.70){
                col = mix(vec3(0.96, 0.98, 1.0), vec3(1.0, 0.93, 0.74), (h.y - 0.35) / 0.35);
            } else {
                col = mix(vec3(1.0, 0.88, 0.65), vec3(1.0, 0.65, 0.42), (h.y - 0.70) / 0.30);
            }
        } else if(h.z > 0.70){
            // Medium prominent stars
            float rank = (h.z - 0.70) / 0.23;
            size = 0.15;
            magnitude = (1.0 + pow(rank, 1.8) * 1.4) * mix(1.0, 0.45, moonIllum);
            col = mix(vec3(0.85, 0.92, 1.0), vec3(1.0, 0.92, 0.80), h.y);
        } else {
            // Faint background stars (heavily washed out under full moon)
            float rank = h.z / 0.70;
            size = 0.085;
            magnitude = (0.35 + pow(rank, 2.0) * 0.65) * mix(1.0, 0.18, moonIllum);
            col = mix(vec3(0.82, 0.90, 1.0), vec3(0.98, 0.94, 0.85), h.y);
        }
        
        #if STAR_ROTATION != 0
            float starAngle = h.y * TAU;
            vec2 rPos = rot2D(starAngle) * fracPos;
            float d = getSunMoonDist(rPos, size);
        #else
            float d = getSunMoonDist(fracPos, size);
        #endif
        
        float edge = fwidth(d);
        float shape = saturate((size - d) / max(edge, 0.001));
        
        if(shape > 0.0){
            float twinkleRate = isConstellation ? 1.2 : 1.6;
            float twinkleDepth = isConstellation ? 0.12 : 0.20;
            float twinkle = sin(time * twinkleRate + h.x * 55.0) * twinkleDepth + (1.0 - twinkleDepth);
            
            // Base output multiplier: calibrated for crisp visibility and clear magnitude contrast
            starOut = col * (magnitude * twinkle * shape * 0.085);
        }
    }
    return starOut;
}

// Procedural Minecraft-style Milky Way nebula with square stepped edges and square star clusters
vec3 getProceduralMilkyWay(in vec3 skyPos, in float time){
    vec3 gPos = vec3(
        dot(skyPos, gCore),
        dot(skyPos, gSide),
        dot(skyPos, gPole)
    );
    
    float bandLat = gPos.z;
    if(abs(bandLat) > 0.52) return vec3(0.0);
    
    float bandLon = atan(gPos.y, gPos.x);
    float normLon = (bandLon + PI) / TAU;
    
    const float BLOCKS_X = 300.0;
    const float BLOCKS_Y = 300.0 / TAU;
    
    float blockX = floor(normLon * BLOCKS_X);
    float blockY = floor(bandLat * BLOCKS_Y);
    vec2 mwBlock = vec2(blockX, blockY);
    
    // Multi-octave periodic noise evaluated on blocky coordinates (strictly square edges)
    float n1 = periodicValueNoise(mwBlock * 0.04, 12.0);
    float n2 = periodicValueNoise(mwBlock * 0.08 + vec2(7.3, 11.1), 24.0);
    float n3 = periodicValueNoise(mwBlock * 0.16 + vec2(15.7, 3.9), 48.0);
    float nebulaNoise = n1 * 0.55 + n2 * 0.30 + n3 * 0.15;
    
    // Galactic core bulge (wider vertically)
    float dLon = (normLon - 0.5) * TAU;
    float dLat = bandLat;
    float coreDist = sqrt(dLon * dLon * 1.8 + dLat * dLat * 9.0);
    float coreBulge = saturate(1.0 - coreDist * 1.2);
    coreBulge = coreBulge * coreBulge;
    
    // Latitude band falloff (stepped per row for blocky structure - wider band)
    float blockLatNorm = (blockY + 0.5) / BLOCKS_Y;
    float latEnvelope = saturate(1.0 - abs(blockLatNorm) * 2.1);
    latEnvelope = latEnvelope * latEnvelope;
    
    float combinedDensity = (nebulaNoise * 0.85 + 0.15) * (latEnvelope * 0.65 + coreBulge * 0.75);
    
    vec3 mwColor = vec3(0.0);
    
    // Tier 1: Outer cosmic violet
    if(combinedDensity > 0.16){
        mwColor = vec3(0.045, 0.015, 0.10);
    }
    // Tier 2: Mid magenta / amethyst
    if(combinedDensity > 0.28){
        mwColor = vec3(0.13, 0.04, 0.18);
    }
    // Tier 3: Inner celestial orchid & cyan accents
    if(combinedDensity > 0.44){
        float accent = hash12(mwBlock + vec2(57.3, 29.1));
        mwColor = accent > 0.80 ? vec3(0.08, 0.20, 0.25) : vec3(0.26, 0.09, 0.24);
    }
    // Tier 4: Core warm starlight
    if(combinedDensity > 0.60){
        float coreFactor = saturate((combinedDensity - 0.60) * 3.5);
        mwColor = mix(vec3(0.45, 0.34, 0.28), vec3(0.72, 0.65, 0.58), coreFactor);
    }
    
    // Luminous core center radiation
    mwColor += vec3(0.42, 0.30, 0.24) * (coreBulge * step(0.22, combinedDensity) * 0.4);
    
    // Dark dust rift (Great Rift)
    float dustN = periodicValueNoise(mwBlock * 0.08 + vec2(15.0, 7.0), 24.0);
    float inRift = step(0.50, dustN) * step(abs(blockLatNorm - 0.02 * sin(dLon * 3.0)), 0.12) * step(abs(dLon - 0.1), 0.85);
    if(inRift > 0.5 && combinedDensity > 0.22){
        mwColor *= 0.18;
    }
    
    // Delicate square stars inside the Milky Way
    // Uses the EXACT SAME celestial cubemap projection as sky stars for 100% rotation consistency
    vec2 mwFaceUV;
    float mwFaceId;
    getCelestialCubemap(skyPos, mwFaceUV, mwFaceId);
    
    const float MW_STAR_GRID = 180.0;
    vec2 mwGridPos = (mwFaceUV * 0.5 + 0.5) * MW_STAR_GRID;
    vec2 mwCell = floor(mwGridPos);
    vec2 mwFrac = fract(mwGridPos) - 0.5;
    
    vec3 sHash = hash32(mwCell + mwFaceId * 157.3);
    float starChance = 0.91 - combinedDensity * 0.09 - coreBulge * 0.05;
    
    if(sHash.x > starChance && combinedDensity > 0.10){
        float starRadius = sHash.y > 0.90 ? 0.22 : (sHash.y > 0.55 ? 0.13 : 0.07);
        #if STAR_ROTATION != 0
            float starAngle = sHash.y * TAU;
            vec2 rFrac = rot2D(starAngle) * mwFrac;
            float sqDist = getSunMoonDist(rFrac, starRadius);
        #else
            float sqDist = getSunMoonDist(mwFrac, starRadius);
        #endif
        float edge = fwidth(sqDist);
        float starShape = saturate((starRadius - sqDist) / max(edge, 0.001));
        
        if(starShape > 0.0){
            float lum = (pow(sHash.z, 2.0) * 1.6 + 0.35) * (1.0 + coreBulge * 0.4) * mix(1.0, 0.20, MOON_PHASE_FACTOR);
            vec3 tint = mix(vec3(0.85, 0.92, 1.0), vec3(1.0, 0.88, 0.72), sHash.y);
            float twinkle = sin(time * 2.2 + sHash.x * 45.0) * 0.2 + 0.8;
            mwColor += tint * (lum * twinkle * starShape * 0.85);
        }
    }
    
    return mwColor;
}
