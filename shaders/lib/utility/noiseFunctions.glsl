// Default noise resolution
const int noiseTextureResolution = 256;

// Noise sample, r for blue noise, g for white noise, and b for cell noise
uniform sampler2D noisetex;

vec3 getRng3(in ivec2 iuv){
    return vec3(texelFetch(noisetex, iuv, 0).x, texelFetch(noisetex, ivec2(255 - iuv.x, iuv.y), 0).x, texelFetch(noisetex, ivec2(iuv.x, 255 - iuv.y), 0).x);
}