float fovMult = gbufferProjection[1].y * 0.72794047;

float lensFlareSimple(in vec2 centerCoord, in vec2 lightDir, in float size, in float dist){
    vec2 flareCoord = (centerCoord + lightDir * dist) * vec2(aspectRatio, 1);
    return squared(squared(max(0.0, 1.0 - length(flareCoord) / (size * fovMult))));
}

float lensFlareRays(in vec2 centerCoord, in vec2 lightDir, in float rayBeam, in float size, in float dist){
    vec2 flareCoord = (centerCoord + lightDir * dist) * vec2(aspectRatio, 1);
    float rays = max(0.0, sin(atan(flareCoord.x, flareCoord.y) * rayBeam));
    float lens = lensFlareSimple(centerCoord, lightDir, size, dist);
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

    #if WORLD_SUN_MOON == 2
        return (lens1 + (lens0 + lens2) * 0.125 + chromaLens) * LENS_FLARE_BRIGHTNESS * sRGBLightCol;
    #elif SUN_MOON_TYPE == 2
        float rays = lensFlareRays(centerCoord, lightDir, 8.0, 0.05, -1.0);
        return (lens1 + (lens0 + lens2) * 0.125 + rays + chromaLens) * LENS_FLARE_BRIGHTNESS * sRGBLightCol;
    #else
        float rays = lensFlareRays(centerCoord, lightDir, 8.0, 0.1, -1.0);
        return (lens1 + (lens0 + lens2) * 0.125 + rays + chromaLens) * LENS_FLARE_BRIGHTNESS * sRGBLightCol;
    #endif
}