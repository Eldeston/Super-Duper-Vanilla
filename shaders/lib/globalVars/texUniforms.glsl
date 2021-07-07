#ifndef GBUFFERS
    // Depth texture 0 with transparents
    uniform sampler2D depthtex0;
#endif

#if defined WATER || defined COMPOSITE
    // Depth texture 1 no transparents
    uniform sampler2D depthtex1;
#endif

#if defined DEFERRED || defined COMPOSITE || defined FINAL
    // Normals
    uniform sampler2D colortex1;
    #ifdef PREVIOUS_FRAME
        // Reflections
        uniform sampler2D colortex5;
    #endif
#endif

#ifndef GBUFFERS
    // Main scene
    uniform sampler2D gcolor;
    // Raw albedo / Bloom
    uniform sampler2D colortex2;
    // Metallic, emissive, roughness
    uniform sampler2D colortex3;
    // Empty, glowing entity, cloud mask
    uniform sampler2D colortex4;
#endif

#if defined COMPOSITE4 || defined FINAL
    // Temporal / TAA, Auto Exposure
    uniform sampler2D colortex6;
#endif

#if !(defined COMPOSITE1 || defined COMPOSITE2 || defined COMPOSITE3 || defined COMPOSITE4)
    // Noise sample, r for blue noise, g for white noise, and b for cell noise
    uniform sampler2D noisetex;
#endif

#if defined GBUFFERS && !(defined BEACON_BEAM || defined BASIC)
    uniform sampler2D texture;
#endif

#if defined COMPOSITE || defined GBUFFERS
    // Shadow color
    uniform sampler2D shadowcolor0;

    // Shadow texture
    uniform sampler2DShadow shadowtex0;
    uniform sampler2DShadow shadowtex1;
#endif