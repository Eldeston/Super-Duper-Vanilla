#if defined COMPOSITE || defined DEFERRED
    // Enable mipmap filtering on shadows
    const bool shadowHardwareFiltering = true;
#endif

const int RGBA1 = 1;

const int RGB8 = 1;

const int RGB16 = 1;
const int RGB16F = 1;

const int RGBA16 = 1;
const int RGBA16F = 1;

/* Texture buffer  settings */
#if defined COMPOSITE || defined DEFERRED || defined COMPOSITE1
    const int gdepthFormat = RGBA16F;
    const int gcolorFormat = RGBA16F;
    const int colortex1Format = RGB16;
    const int colortex2Format = RGB8;
    const int colortex3Format = RGB8;
    const int colortex4Format = RGB8;
    const int colortex5Format = RGB16;
    const int colortex6Format = RGBA16F;
    const int colortex7Format = RGB16;
#endif

#if defined COMPOSITE || defined DEFERRED || defined COMPOSITE1 || defined COMPOSITE2 || defined COMPOSITE3
    const bool gcolorMipmapEnabled = true;
    const bool colortex6MipmapEnabled = true;
    const bool colortex7MipmapEnabled = true;

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
    const int shadowMapResolution = 1024; // Shadow map resolution [512 1024 1536 2048 2560 3072 3584 4096 4608 5120]
    // Shadow bias
    const float shdBias = 0.021; // Don't go below the default value otherwise it'll mess up lighting
    const float sunPathRotation = 45.0; // Light/sun/moon angle by degrees [-63.0 -54.0 -45.0 -36.0 -27.0 -18.0 -9.0 0.0 9.0 18.0 27.0 36.0 45.0 54.0 63.0]
#endif