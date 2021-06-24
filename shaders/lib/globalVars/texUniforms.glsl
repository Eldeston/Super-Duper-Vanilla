// Depth texture
uniform sampler2D depthtex0;

#ifndef GBUFFERS
    // Main scene
    uniform sampler2D gcolor;
    // Normals
    uniform sampler2D colortex1;
    // Lightmap, subsurface scattering / Bloom
    uniform sampler2D colortex2;
    // Metallic, emissive, roughness
    uniform sampler2D colortex3;
    // AO, cloud mask, solid mask
    uniform sampler2D colortex4;

    // Reflections
    uniform sampler2D colortex5;
    // Temporal / TAA, Auto Exposure
    uniform sampler2D colortex6;
    // Raw albedo
    uniform sampler2D colortex7;
#endif

// Noise sample, r for blue noise, g for white noise, and b for cell noise
uniform sampler2D noisetex;

#if defined COMPOSITE || defined DEFERRED || defined GBUFFERS
    // Shadow color
    uniform sampler2D shadowcolor0;

    // Shadow texture
    uniform sampler2DShadow shadowtex0;
    uniform sampler2DShadow shadowtex1;
#endif