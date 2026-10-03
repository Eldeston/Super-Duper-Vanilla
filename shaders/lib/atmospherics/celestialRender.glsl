/*
================================ /// Super Duper Vanilla v1.3.8 /// ================================

    Celestial Rendering (Sun, Moon Phases, and Shape Functions)
    Supports in-game resource packs for sun and all 8 moon phases.

================================ /// Super Duper Vanilla v1.3.8 /// ================================
*/

#ifndef CELESTIAL_RENDER_GLSL
#define CELESTIAL_RENDER_GLSL

float getSunMoonDist(in vec2 coord, in float halfSize){
    float r = SUN_MOON_ROUNDNESS * halfSize;
    vec2 q = abs(coord) - vec2(halfSize - r);
    return min(max(q.x, q.y), 0.0) + length(max(q, vec2(0.0))) - r + halfSize;
}

float getSunMoonDist(in vec2 coord){
    return getSunMoonDist(coord, WORLD_SUN_MOON_SIZE);
}

// Round sun and moon
float getSunMoonShape(in float skyPosZ){
    float glowRadius = WORLD_SUN_MOON_SIZE * 0.5;
    return min(1.0, exp2((glowRadius - sqrt(1.0 - skyPosZ * skyPosZ)) * (1.5 / WORLD_SUN_MOON_SIZE)));
}

// Shape-adjusted sun and moon
float getSunMoonShape(in vec2 skyPos){
    float glowRadius = WORLD_SUN_MOON_SIZE * 0.5;
    return min(1.0, exp2((glowRadius - getSunMoonDist(skyPos, glowRadius)) * (1.5 / WORLD_SUN_MOON_SIZE)));
}

#if WORLD_SUN_MOON == 1 || WORLD_SUN_MOON == 2
    uniform sampler2D sunTex;
#endif

#if WORLD_SUN_MOON == 1
    uniform sampler2D moonTex0;
    uniform sampler2D moonTex1;
    uniform sampler2D moonTex2;
    uniform sampler2D moonTex3;
    uniform sampler2D moonTex4;
    uniform sampler2D moonTex5;
    uniform sampler2D moonTex6;
    uniform sampler2D moonTex7;

    vec4 fetchMoonTex(in vec2 uv, in int p){
        switch(p){
            case 0: return textureLod(moonTex0, uv, 0.0);
            case 1: return textureLod(moonTex1, uv, 0.0);
            case 2: return textureLod(moonTex2, uv, 0.0);
            case 3: return textureLod(moonTex3, uv, 0.0);
            case 4: return textureLod(moonTex4, uv, 0.0);
            case 5: return textureLod(moonTex5, uv, 0.0);
            case 6: return textureLod(moonTex6, uv, 0.0);
            case 7: return textureLod(moonTex7, uv, 0.0);
            default: return textureLod(moonTex0, uv, 0.0);
        }
    }

    vec3 getMoonRender(in vec2 moonCoord, in vec3 moonColor, in float weatherFadeAmount){
        float dist = getSunMoonDist(moonCoord, WORLD_SUN_MOON_SIZE);
        
        // Anti-aliased boundary mask (1.0 inside moon disc, 0.0 outside)
        float moonDisc = saturate((WORLD_SUN_MOON_SIZE - dist) / max(fwidth(dist), 0.001));
        
        // Glow with radius smaller than the texture, extending smoothly into the sky
        float glowRadius = WORLD_SUN_MOON_SIZE * 0.5;
        float distGlow = getSunMoonDist(moonCoord, glowRadius);
        float glow = min(1.0, exp2((glowRadius - distGlow) * (1.5 / WORLD_SUN_MOON_SIZE)));
        if(glow <= 0.0001 && moonDisc <= 0.0) return vec3(0.0);
        
        #if WORLD_ID == 0
            vec2 normCoord = moonCoord / WORLD_SUN_MOON_SIZE;
            vec2 uvInMoon = vec2(normCoord.x, -normCoord.y) * 0.5 + 0.5;
            int p = clamp(moonPhase, 0, 7);
            
            // Check if resource pack fills entire texture or uses vanilla centered [12..20]/32
            vec4 corner = fetchMoonTex(vec2(0.0625), p);
            bool isFullQuad = corner.a > 0.1 && (corner.r + corner.g + corner.b) > 0.25;
            vec2 sampleUV = isFullQuad ? uvInMoon : (vec2(12.5) + saturate(uvInMoon) * 7.0) / 32.0;
            
            vec4 moonSample = fetchMoonTex(sampleUV, p);
            
            float litMask;
            vec3 craterTex;
            
            // Check if texture was sampled successfully
            if(moonSample.a > 0.05 && (max(moonSample.r, max(moonSample.g, moonSample.b)) > 0.02 || p == 4)){
                // Lit vs unlit pixels in vanilla texture (unlit are ~0.05..0.17, lit are ~0.31..0.85)
                litMask = (p == 4) ? 0.0 : smoothstep(0.18, 0.28, max(moonSample.r, max(moonSample.g, moonSample.b)));
                craterTex = toLinear(moonSample.rgb * 1.176);
            } else {
                // Procedural fallback mask if texture sampler is not yet ready
                float phaseProg = float(p) / 8.0;
                float phaseAngle = phaseProg * TAU;
                float illum = -cos(phaseAngle);
                float sideSign = (phaseProg < 0.5) ? 1.0 : -1.0;
                float horiz = normCoord.x * sideSign;
                litMask = saturate((horiz + illum + 0.1) * 5.0);
                if(p == 0) litMask = 1.0;
                if(p == 4) litMask = 0.0;
                craterTex = vec3(0.92);
            }
            
            // Faint ash light / earthshine on the dark unlit side
            float ashLight = 0.015 * (1.0 - litMask);
            
            // Inside the moon body: lit crater texture + faint ash light
            vec3 bodyCol = moonColor * (craterTex * litMask + vec3(ashLight));
            
            // Outside glare scales with moon phase luminosity
            float glarePhase = MOON_PHASE_FACTOR * MOON_PHASE_FACTOR;
            vec3 glareCol = moonColor * (glow * glarePhase);
            
            // Combine body (inside disc) and outside glare (beyond disc)
            vec3 moonPattern = mix(glareCol, glareCol * (1.0 - litMask) + bodyCol, moonDisc);
            float celestialVis = 1.0 - weatherFadeAmount;
            return moonPattern * (sunMoonIntensitySqrd * celestialVis);
        #else
            float sunMoonShape = glow * sunMoonIntensitySqrd;
            float celestialVis = 1.0 - weatherFadeAmount;
            return moonColor * (sunMoonShape * celestialVis);
        #endif
    }

    vec3 getSunRender(in vec2 sunCoord, in vec3 sunColor, in float weatherFadeAmount){
        float dist = getSunMoonDist(sunCoord, WORLD_SUN_MOON_SIZE);
        
        // Anti-aliased boundary mask (1.0 inside sun disc, 0.0 outside)
        float sunDisc = saturate((WORLD_SUN_MOON_SIZE - dist) / max(fwidth(dist), 0.001));
        
        // Glow with radius smaller than the texture, extending smoothly into the sky
        float glowRadius = WORLD_SUN_MOON_SIZE * 0.5;
        float distGlow = getSunMoonDist(sunCoord, glowRadius);
        float glow = min(1.0, exp2((glowRadius - distGlow) * (1.5 / WORLD_SUN_MOON_SIZE)));
        if(glow <= 0.0001 && sunDisc <= 0.0) return vec3(0.0);
        
        #if WORLD_ID == 0
            vec2 normCoord = sunCoord / WORLD_SUN_MOON_SIZE;
            vec2 uvInBody = vec2(normCoord.x, -normCoord.y) * 0.5 + 0.5;
            
            // Check if resource pack fills entire texture or uses vanilla centered [12..20]/32
            vec4 corner = textureLod(sunTex, vec2(0.0625), 0.0);
            bool isFullQuad = corner.a > 0.1 && (corner.r + corner.g + corner.b) > 0.25;
            vec2 sampleUV = isFullQuad ? uvInBody : (vec2(12.5) + saturate(uvInBody) * 7.0) / 32.0;
            
            vec4 sunSample = textureLod(sunTex, sampleUV, 0.0);
            
            vec3 sunTexCol;
            if(sunSample.a > 0.05 && (sunSample.r + sunSample.g + sunSample.b) > 0.05){
                sunTexCol = toLinear(sunSample.rgb);
                float maxVal = max(sunTexCol.r, max(sunTexCol.g, sunTexCol.b));
                if(maxVal > 0.01){
                    sunTexCol /= max(maxVal, 0.85);
                }
            } else {
                sunTexCol = vec3(1.0);
            }
            
            vec3 bodyCol = sunColor * sunTexCol;
            vec3 glareCol = sunColor * glow;
            
            vec3 sunPattern = mix(glareCol, bodyCol, sunDisc);
            float celestialVis = 1.0 - weatherFadeAmount;
            return sunPattern * (sunMoonIntensitySqrd * celestialVis);
        #else
            float sunShape = glow * sunMoonIntensitySqrd;
            float celestialVis = 1.0 - weatherFadeAmount;
            return sunColor * (sunShape * celestialVis);
        #endif
    }
#endif // WORLD_SUN_MOON == 1

#if WORLD_SUN_MOON == 2
    vec3 sampleBlackHoleTex(in vec2 projPos, in float bhHalfSize){
        vec2 normCoord = projPos / (bhHalfSize * 1.25);
        vec2 uvInBody = vec2(normCoord.x, -normCoord.y) * 0.5 + 0.5;
        vec4 corner = textureLod(sunTex, vec2(0.0625), 0.0);
        bool isFullQuad = corner.a > 0.1 && (corner.r + corner.g + corner.b) > 0.25;
        vec2 sampleUV = isFullQuad ? uvInBody : (vec2(12.5) + saturate(uvInBody) * 7.0) / 32.0;
        vec4 sunSample = textureLod(sunTex, sampleUV, 0.0);

        vec3 sunTexCol;
        if(sunSample.a > 0.05 && (sunSample.r + sunSample.g + sunSample.b) > 0.05){
            sunTexCol = toLinear(sunSample.rgb);
            float maxVal = max(sunTexCol.r, max(sunTexCol.g, sunTexCol.b));
            if(maxVal > 0.01) sunTexCol /= max(maxVal, 0.85);
        } else {
            sunTexCol = vec3(1.0);
        }

        float texBorderFade = saturate((1.0 - max(abs(normCoord.x), abs(normCoord.y))) * 8.0);
        float texLum = dot(sunTexCol, vec3(0.299, 0.587, 0.114));
        return mix(vec3(1.0), mix(vec3(texLum), sunTexCol, 0.20), texBorderFade);
    }

    float getSquareAngle(in vec2 p){
        float ax = abs(p.x), ay = abs(p.y);
        float M = max(ax, ay);
        if(M < 0.00001) return 0.0;
        float s;
        if(ay >= ax){
            s = p.y > 0.0 ? (0.25 - p.x / (8.0 * M)) : (0.75 + p.x / (8.0 * M));
        } else {
            s = p.x > 0.0 ? (p.y / (8.0 * M)) : (0.50 - p.y / (8.0 * M));
        }
        return fract(s);
    }

    vec3 getBlackHoleRender(
        inout vec3 skyPos,
        in vec3 lightCol,
        in float sunMoonIntensitySqrd,
        in float fragmentFrameTime,
        out bool isHoleCore
    ){
        isHoleCore = false;
        if(skyPos.z <= 0.0) return vec3(0.0);

        const float bhHalfSize = WORLD_SUN_MOON_SIZE;
        const float z0 = inversesqrt(bhHalfSize * bhHalfSize + 1.0);
        const float blackHoleSize = z0 * 1024.0;

        vec2 projPos = skyPos.xy / skyPos.z;
        float dist = getSunMoonDist(projPos, bhHalfSize);
        // Square box profile matching Minecraft celestials (respects SUN_MOON_ROUNDNESS)
        float boxDist = mix(max(abs(projPos.x), abs(projPos.y)), dist, SUN_MOON_ROUNDNESS);
        float shapeZ = inversesqrt(boxDist * boxDist + 1.0);
        float blackHole = blackHoleSize - shapeZ * 1024.0;

        // Inside event horizon core: return immediately
        if(blackHole <= 0.0){
            isHoleCore = true;
            return vec3(0.0);
        }

        // Anti-aliased core boundary
        float fw = max(fwidth(boxDist), 0.001);
        float coreCut = saturate((boxDist - bhHalfSize) / fw);
        if(coreCut <= 0.0){
            isHoleCore = true;
            return vec3(0.0);
        }

        float edgeDist = max(0.0, boxDist - bhHalfSize);
        float normDist = edgeDist / bhHalfSize;

        // Angle coordinate conforming strictly to square geometry when SUN_MOON_ROUNDNESS == 0.0
        float sqAngle = getSquareAngle(projPos);
        float circAngle = fract(atan(projPos.y, projPos.x) / TAU);
        float geomAngle = mix(sqAngle, circAngle, SUN_MOON_ROUNDNESS);

        // Inward differential rotation (Keplerian-like swirl that winds tightly into the event horizon)
        const float twistRate = 3.8;
        float diffRot = twistRate / (0.28 + normDist * 0.88);
        float spinTime = fragmentFrameTime * 0.0032;

        // Dual high-impact grand-design spiral arms conforming to the square/round shape
        float spiralPhase1 = geomAngle * 2.0 + diffRot - spinTime;
        float spiralPhase2 = spiralPhase1 + 0.5;

        float arm1 = cos(fract(spiralPhase1) * TAU);
        float arm2 = cos(fract(spiralPhase2) * TAU);

        // Crisp, high-contrast luminous filament profiles
        float armCore1 = pow(max(0.0, arm1 * 0.5 + 0.5), 2.6);
        float armCore2 = pow(max(0.0, arm2 * 0.5 + 0.5), 3.4) * 0.65;
        float armStructure = armCore1 + armCore2;

        // Inflowing plasma turbulence along the spiral arms
        vec2 noiseCoord1 = vec2(spiralPhase1 * 0.50, normDist * 2.2 - fragmentFrameTime * 0.0028);
        vec2 noiseCoord2 = vec2(spiralPhase1 * 1.05 + 0.25, normDist * 4.0 - fragmentFrameTime * 0.0045);
        float streamNoise1 = textureLod(noisetex, noiseCoord1, 0).x;
        float streamNoise2 = textureLod(noisetex, noiseCoord2, 0).y;
        float plasmaStream = mix(streamNoise1, streamNoise2, 0.40);

        // Prominent, high-impact composite spiral
        float spiralLuminance = armStructure * (0.55 + 0.85 * plasmaStream) + 0.15 * plasmaStream;

        // Accretion disk span (extends gracefully across normDist in [0, 1.85])
        float diskSpan = saturate((1.85 - normDist) / 1.85);
        float diskMask = diskSpan * diskSpan * (3.0 - 2.0 * diskSpan);

        // Brilliant inner accretion ring (photon sphere glow) right at the core border
        float innerRing = exp2(-normDist * 8.0) * 1.6;

        float totalSpiral = (spiralLuminance * 2.4 + innerRing) * diskMask;

        // Multi-layer smooth analytical aura (strictly zero noise to prevent any banding or noise artifacts)
        float auraCore  = exp2(-normDist * 4.2) * 0.55;
        float auraMid   = exp2(-normDist * 1.5) * 0.40;
        float auraOuter = exp2(-normDist * 0.65) * 0.22;

        // Smooth cubic window to ensure the outer border decays to EXACTLY 0.0 without edge banding
        float auraWindow = saturate((3.2 - normDist) / 1.8);
        float auraCutoff = auraWindow * auraWindow * (3.0 - 2.0 * auraWindow);

        float cleanAura = (auraCore + auraMid + auraOuter) * auraCutoff;

        // Relativistic Doppler effect & subtle color shift
        vec2 tiltedPos = rot2D(0.21) * projPos;
        float r = max(boxDist, 0.0001);
        float losVel = clamp(-tiltedPos.x / r * sqrt(clamp(bhHalfSize / r, 0.0, 1.0)), -1.0, 1.0);
        float dopplerBeaming = 1.0 + losVel * 0.42;
        float dopplerT = losVel * 0.5 + 0.5;
        vec3 dopplerTint = mix(
            vec3(1.30, 0.50, 0.88), // Plum-magenta (receding)
            vec3(0.60, 0.85, 1.50), // Electric cyan-violet (approaching)
            dopplerT
        );
        vec3 dopplerEffect = dopplerTint * dopplerBeaming;

        // Custom sun texture integration (smoothly tinted without extinguishing the spiral)
        vec3 themedTexCol = sampleBlackHoleTex(projPos, bhHalfSize);
        vec3 texWeight = mix(vec3(1.0), themedTexCol, 0.35);

        // Combine prominent accretion spiral with pristine, artifact-free outer aura
        vec3 diskCol = lightCol * dopplerEffect * texWeight * totalSpiral;
        vec3 auraCol = lightCol * mix(vec3(0.92, 0.82, 1.15), dopplerTint, 0.35) * (cleanAura * 0.35);
        vec3 bhCol = (diskCol + auraCol) * (sunMoonIntensitySqrd * 0.40) * coreCut;

        // Extended gravitational warping reach (near-field vortex + far-field well)
        float normD = normDist;
        float warpNear = 1.0 / (1.0 + 2.0 * normD + 2.5 * normD * normD);
        float farWindow = saturate(1.0 - normD * 0.08);
        float smoothFarWindow = farWindow * farWindow * (3.0 - 2.0 * farWindow);
        float warpFar = exp2(-normD * 0.55) * smoothFarWindow;
        float warpImpact = (0.58 * warpNear + 0.42 * warpFar) * smoothFarWindow;

        // Apply rotational swirl and lensing deflection across surrounding sky
        if(warpImpact > 0.0){
            float rotAngle = warpImpact * (TAU * 4.0);
            float lensDeflect = warpImpact * 0.35;
            vec2 warpedProj = rot2D(rotAngle) * projPos * (1.0 + lensDeflect);
            skyPos.xy = warpedProj * skyPos.z;
        }

        return bhCol;
    }
#endif // WORLD_SUN_MOON == 2

#endif // CELESTIAL_RENDER_GLSL

