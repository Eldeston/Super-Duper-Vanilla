// Default noise resolution
const int noiseTextureResolution = 256;

#ifndef NOISETEX_DECLARED
    #define NOISETEX_DECLARED
    uniform sampler2D noisetex;
#endif

vec3 getRng3(in ivec2 iuv){
    return vec3(texelFetch(noisetex, iuv, 0).x, texelFetch(noisetex, ivec2(255 - iuv.x, iuv.y), 0).x, texelFetch(noisetex, ivec2(iuv.x, 255 - iuv.y), 0).x);
}