const int RGBA1 = 1;

const int RGB8 = 1;
const int RGB16 = 1;

const int RGB16F = 1;
const int RGBA16F = 1;

#if !defined GBUFFERS || !defined FINAL
    const int gcolorFormat = RGBA16F;
#else
    const int gcolorFormat = RGB16;
#endif

const int gdepthFormat = RGB16F;
const int colortex1Format = RGB16;
const int colortex2Format = RGB8;
const int colortex3Format = RGB8;
const int colortex4Format = RGB8;
const int colortex5Format = RGB16;

#if !defined GBUFFERS || !defined FINAL
    const int colortex6Format = RGBA16F;
#else
    const int colortex6Format = RGB16;
#endif

const int colortex7Format = RGB16;

#if !defined GBUFFERS || !defined FINAL
    const bool gcolorMipmapEnabled = true;
    const bool colortex6MipmapEnabled = true;
    const bool colortex7MipmapEnabled = true;

    const bool colortex5Clear = false;
    const bool colortex6Clear = false;
#endif

// Depth texture
uniform sampler2D depthtex0;

#if !defined GBUFFERS
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
#endif

// Default resolution
const int noiseTextureResolution = 256;

#ifdef GBUFFERS
    // Default AO
    const float ambientOcclusionLevel = 1.0;
#endif

// Noise sample, r for blue noise, g for white noise, and b for cell noise
uniform sampler2D noisetex;

// Filter by iq
vec4 tex2DFilter(sampler2D image, vec2 st, vec2 texRes){
    vec2 uv = st * texRes + 0.5;
    vec2 iuv = floor(uv); vec2 fuv = fract(uv);
    uv = iuv + fuv * fuv * fuv * (fuv * (fuv * 6.0 - 15.0) + 10.0);
    uv = (uv - 0.5) / texRes;
    return texture2D(image, uv);
}

// Noise texture
vec4 getRandTex(vec2 st, int tile){
	return texture2D(noisetex, st * tile);
}

vec3 getRand3(vec2 st, int tile){
    st *= tile;
    float x = texture2D(noisetex, st).x;
    float y = texture2D(noisetex, vec2(-st.x, st.y)).x;
    float z = texture2D(noisetex, -st).x;
    if(NOISE_SPEED == 0) return fract(vec3(x, y, z) * 4.0);
    return fract(vec3(x, y, z) * 4.0 + frameTimeCounter * NOISE_SPEED);
}

float getCellNoise(vec2 st){
    float d0 = texture2D(noisetex, st + frameTimeCounter * 0.0125).z;
    float d1 = texture2D(noisetex, st * 4.0 - frameTimeCounter * 0.05).z;
    #ifdef INVERSE
        return 1.0 - d0 * 0.875 + d1 * 0.125;
    #else
        return d0 * 0.875 + d1 * 0.125;
    #endif
}

// Convert height map of water to a normal map
vec4 H2NWater(vec2 st){
    float waterPixel = WATER_BLUR_SIZE / noiseTextureResolution;
	vec2 waterUv = st / WATER_TILE_SIZE;

	float d = getCellNoise(waterUv);
	float dx = (d - getCellNoise(waterUv + vec2(waterPixel, 0))) / waterPixel;
	float dy = (d - getCellNoise(waterUv + vec2(0, waterPixel))) / waterPixel;

    #ifdef INVERSE
        d = 1.0 - d;
    #endif
    
    return vec4(normalize(vec3(dx, dy, WATER_DEPTH_SIZE)), d);
}

float getParallaxClouds3D(sampler2D source, vec2 startUv, float thickness, float dither, int steps){
    float stepSize = 1.0 / float(steps);
    vec2 endUv = startUv * stepSize * thickness * (1.0 + dither * 0.2);

    float clouds = 0.0;
    for(int i = 0; i < steps; i++){
        startUv += endUv;
        clouds += texture2D(source, startUv + vec2(frameTimeCounter * 0.001, 0)).r;
    }
    return sqrt(clouds * stepSize);
}