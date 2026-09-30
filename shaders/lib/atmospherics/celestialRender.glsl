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

#if WORLD_SUN_MOON == 1
    uniform sampler2D sunTex;
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
            return moonPattern * (sunMoonIntensitySqrd * (1.0 - weatherFadeAmount));
        #else
            float sunMoonShape = glow * sunMoonIntensitySqrd;
            return moonColor * (sunMoonShape * (1.0 - weatherFadeAmount));
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
            return sunPattern * (sunMoonIntensitySqrd * (1.0 - weatherFadeAmount));
        #else
            float sunShape = glow * sunMoonIntensitySqrd;
            return sunColor * (sunShape * (1.0 - weatherFadeAmount));
        #endif
    }
#endif // WORLD_SUN_MOON == 1

#endif // CELESTIAL_RENDER_GLSL
