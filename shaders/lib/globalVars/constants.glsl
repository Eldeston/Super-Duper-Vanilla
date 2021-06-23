#if defined COMPOSITE || defined DEFERRED || defined COMPOSITE1 || defined COMPOSITE2 || defined COMPOSITE3
    const bool gcolorMipmapEnabled = true;
    const bool colortex2MipmapEnabled = true;
    const bool colortex6MipmapEnabled = true;

    const bool colortex5Clear = false;
    const bool colortex6Clear = false;
#endif

// Default resolution
const int noiseTextureResolution = 256;

#ifdef GBUFFERS
    // Default AO
    const float ambientOcclusionLevel = 1.0;
#endif

#if defined COMPOSITE || defined DEFERRED
    // Enable mipmap filtering on shadows
    const bool shadowHardwareFiltering = true;
    const int shadowMapResolution = 512; // Shadow map resolution [512 1024 1536 2048 2560 3072 3584 4096 4608 5120]
    // Shadow bias
    const float shdBias = 0.021; // Don't go below the default value otherwise it'll mess up lighting
    const float sunPathRotation = 45.0; // Light/sun/moon angle by degrees [-63.0 -54.0 -45.0 -36.0 -27.0 -18.0 -9.0 0.0 9.0 18.0 27.0 36.0 45.0 54.0 63.0]
#endif