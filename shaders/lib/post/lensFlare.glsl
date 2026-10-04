float getLensDist(in vec2 lensCoord, in float halfSize){
    float r = SUN_MOON_ROUNDNESS * halfSize;
    vec2 q = abs(lensCoord) - vec2(halfSize - r);
    return min(max(q.x, q.y), 0.0) + length(max(q, vec2(0.0))) - r + halfSize;
}

float lensShape(in vec2 lensCoord, in float flareRadius){
    #if WORLD_SUN_MOON == 2
        float ringRadius = cubed(WORLD_SUN_MOON_SIZE);
        return abs(getLensDist(lensCoord, ringRadius) - ringRadius);
    #else
        return getLensDist(lensCoord, flareRadius);
    #endif
}

float lensFlareSimple(in vec2 centerCoord, in vec2 lightDir, in float size, in float dist){
    vec2 flareCoord = centerCoord + lightDir * dist;
    float flareRadius = max(0.0001, size * shdLightDirScreenSpace.z);
    return squared(squared(max(0.0, 1.0 - lensShape(vec2(flareCoord.x * aspectRatio, flareCoord.y), flareRadius) / flareRadius)));
}

float lensFlareRays(in vec2 centerCoord, in vec2 lightDir, in float rayBeam, in float size, in float dist){
    float lens = lensFlareSimple(centerCoord, lightDir, size, dist);
    if(lens <= 0.0) return 0.0;
    vec2 flareCoord = centerCoord + lightDir * dist;
    float rays = max(0.0, sin(atan(flareCoord.x * aspectRatio, flareCoord.y) * rayBeam));
    return rays * lens + lens;
}

vec3 chromaLens(in vec2 centerCoord, in vec2 lightDir, in float chromaDist, in float size, in float dist){
    return vec3(
        lensFlareSimple(centerCoord, lightDir, size, dist),
        lensFlareSimple(centerCoord, lightDir, size, dist * (1.0 - chromaDist)),
        lensFlareSimple(centerCoord, lightDir, size, dist * (1.0 - chromaDist * 2.0))
        );
}

vec3 getLensFlare(in vec2 centerCoord, in vec2 lightDir){
    float lens0 = lensFlareSimple(centerCoord, lightDir, 0.2, 0.75);
    float lens1 = lensFlareSimple(centerCoord, lightDir, 0.1, 0.5);
    float lens2 = lensFlareSimple(centerCoord, lightDir, 0.05, 0.25);
    
    vec3 chromaLens = chromaLens(centerCoord, lightDir, 0.05, 0.05, -0.5);

    #ifndef MOON_PHASE_FACTOR
        #define MOON_PHASE_FACTOR 1.0
    #endif
    #ifdef FORCE_DISABLE_DAY_CYCLE
        float flarePhase = 1.0;
    #else
        #if WORLD_ID == 0
            float flarePhase = (lightningFlareFactor > 0.0 || dayCycle > 1.0) ? 1.0 : (MOON_PHASE_FACTOR * MOON_PHASE_FACTOR);
        #else
            float flarePhase = dayCycle > 1.0 ? 1.0 : (MOON_PHASE_FACTOR * MOON_PHASE_FACTOR);
        #endif
    #endif

    #if WORLD_SUN_MOON == 2
        return (lens1 + (lens0 + lens2) * 0.125 + chromaLens) * (LENS_FLARE_STRENGTH * 0.25) * sRGBLightCol;
    #else
        float rays = lensFlareRays(centerCoord, lightDir, 8.0, 0.1, -1.0);
        return (lens1 + (lens0 + lens2) * 0.125 + rays + chromaLens) * (LENS_FLARE_STRENGTH * flarePhase) * sRGBLightCol;
    #endif
}