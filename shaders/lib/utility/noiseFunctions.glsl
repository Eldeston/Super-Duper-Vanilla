// Default noise resolution
const int noiseTextureResolution = 256;

// Noise sample, r for blue noise, g for white noise, and b for cell noise
uniform sampler2D noisetex;

vec3 getRng3(in ivec2 iuv){
    // Fetch three channels from different noise texture coordinates for true decorrelation.
    // Using the same texel for r, g, b causes correlated noise that produces banding
    // artifacts on water surfaces and in shadow dithering.
    // Credits: Kawwabi
    return vec3(
        texelFetch(noisetex, iuv, 0).x,
        texelFetch(noisetex, ivec2(noiseTextureResolution - 1 - iuv.x, iuv.y), 0).x,
        texelFetch(noisetex, ivec2(iuv.x, noiseTextureResolution - 1 - iuv.y), 0).x
    );
}
