const int RGBA16F = 1;
const int RGBA32F = 1;
const int RGB8 = 1;
const int RGB16 = 1;

const int gcolorFormat = RGBA16F;
const int gdepthFormat = RGBA32F;
const int colortex1Format = RGB16;
const int colortex2Format = RGB8;
const int colortex3Format = RGB8;
const int colortex4Format = RGB8;
const int colortex5Format = RGB8;
const int colortex6Format = RGBA16F;

const bool gcolorMipmapEnabled = true;
const bool colortex6MipmapEnabled = true;

const bool colortex6Clear = false;

// Depth texture
uniform sampler2D depthtex0;
// Main texture color 0
uniform sampler2D gcolor;
// Normal map buffer(rgb) 2
uniform sampler2D colortex1;

// Lightmap coord(rg) and subsurface scattering 2
uniform sampler2D colortex2;
// Metallic, emissive, roughness
uniform sampler2D colortex3;
// AO, cloud mask, alpha
uniform sampler2D colortex4;

// Unused
uniform sampler2D colortex5;
// Reflection, exposure, and bloom buffer
uniform sampler2D colortex6;
// Unused
uniform sampler2D colortex7;

// Default resolution
const int noiseTextureResolution = 256;

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

// Get random vec
vec2 getRandVec(vec2 st, int tile){
	float n = getRandTex(st, tile).x * PI * 2;
	return vec2(cos(n), sin(n));
}

vec3 getRand3(vec2 st, int tile){
    float x = texture2D(noisetex, st * tile).x;
    float y = texture2D(noisetex, vec2(-st.x, st.y) * tile).x;
    float z = texture2D(noisetex, -st * tile).x;
	return vec3(x, y, z);
}

float getCellNoise(vec2 st){
    float d0 = texture2D(noisetex, st + frameTimeCounter * 0.00675).z;
    float d1 = texture2D(noisetex, st * 4.0 - frameTimeCounter * 0.025).z;
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
	float dx = (d - getCellNoise(waterUv + vec2(waterPixel, 0.0))) / waterPixel;
	float dy = (d - getCellNoise(waterUv + vec2(0.0, waterPixel))) / waterPixel;

    #ifdef INVERSE
        d = 1.0 - d;
    #endif
    
    return vec4(normalize(vec3(dx, dy, WATER_DEPTH_SIZE)), d);
}