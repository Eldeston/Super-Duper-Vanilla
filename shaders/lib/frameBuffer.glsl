const int RGBA16F = 1;
const int gcolorFormat = RGBA16F;

const bool gcolorMipmapEnabled = true;
const bool colortex3MipmapEnabled = true;
const bool colortex6MipmapEnabled = true;
const bool colortex6Clear = false;

uniform float viewWidth;
uniform float viewHeight;

// Depth texture
uniform sampler2D depthtex0;
// Main texture color 0
uniform sampler2D gcolor;
// Lightmap coord(rg) and sky mask(b) 1
uniform sampler2D colortex1;
// Normal map buffer(rgb) 2
uniform sampler2D colortex2;
// Bloom buffer 3
uniform sampler2D colortex3;
// Material buffer 4
uniform sampler2D colortex4;
// Material buffer 5
uniform sampler2D colortex5;
// Loop trail buffer 6
uniform sampler2D colortex6;

// Default resolution
const int noiseTextureResolution = 256;

// Noise sample(blueNoise3)
uniform sampler2D noisetex;

// Lm noise tile
const int lmNoiseTile = 8;

// Filter by iq
vec4 tex2DFilter(sampler2D image, vec2 st, vec2 texRes){
    vec2 uv = st * texRes + 0.5;
    vec2 iuv = floor(uv); vec2 fuv = fract(uv);
    uv = iuv + fuv * fuv * fuv * (fuv * (fuv * 6.0 - 15.0) + 10.0);
    uv = (uv - 0.5) / texRes;
    return texture2D(image, uv);
}

// Get depth
float getDepth(vec2 st){
    return texture2D(depthtex0, st).r;
}

// Get light map
vec2 getLightMap(vec2 st){
    return texture2D(colortex1, st).xy;
}

// Get sky mask
float getSkyMask(vec2 st){
    return texture2D(colortex1, st).z;
}

// Get normal
vec3 getNormal(vec2 st){
    return texture2D(colortex2, st).rgb * 2.0 - 1.0;
}

// Linear noise texture
vec4 getRandTex(vec2 st, int tile){
	return texture2D(noisetex, st * tile + 0.5);
}

// Get random vec
vec2 getRandVec(vec2 st, int tile){
	float n = getRandTex(st, tile).x * PI * 2;
	return vec2(cos(n), sin(n));
}

float getCellNoise(vec2 st){
    float d0 = texture2D(noisetex, st + frameTimeCounter * 0.00675).z;
    float d1 = texture2D(noisetex, st * 4.0 - frameTimeCounter * 0.025).z;
    return d0 * 0.875 + d1 * 0.125;
}