// Depth texture
uniform sampler2D depthtex0;

#ifndef GBUFFERS
    // Albedo texture color 0
    uniform sampler2D gcolor;
    // Normal map buffer(rgb)
    uniform sampler2D colortex1;
    // Lightmap coord(rg) and subsurface scattering
    uniform sampler2D colortex2;
    // Metallic, emissive, roughness
    uniform sampler2D colortex3;
    // AO, cloud mask, alpha
    uniform sampler2D colortex4;

    // Reflections
    uniform sampler2D colortex5;
    // Accumulation buffer, and exposure
    uniform sampler2D colortex6;
    // Bloom
    uniform sampler2D colortex7;
    // Temporal AA
    uniform sampler2D colortex8;
#endif

// Noise sample, r for blue noise, g for white noise, and b for cell noise
uniform sampler2D noisetex;

#if defined COMPOSITE || defined DEFERRED
    // Shadow color
    uniform sampler2D shadowcolor0;

    // Shadow texture
    uniform sampler2DShadow shadowtex0;
    uniform sampler2DShadow shadowtex1;
#endif