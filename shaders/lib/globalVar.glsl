#define PI 3.14159265359
#define PI2 6.28318530718

// Material PBR struct
struct matPBR{
    // Albedo texture
    vec3 albedo_t;
    // Normal map
    vec3 normal_m;
    // Specular map
    float specular_m;
    // Subsurface scattering
    float ss_m;
    // Emissive map
	float emissive_m;
    // Translucency
    float alpha_m;
    // Ambient map
    float ambient_m;
};

struct positionVectors{
    // Shadow position
    vec4 shdPos;
    // Local pos
    vec4 localPos;
    // View position
    vec3 viewPos;
    // Camera position
    vec3 camPos;
    // World position
    vec3 worldPos;
    // Light position
    vec3 lightPos;
    // Texcoord
    vec2 st;
    // Lightmap
    vec2 lm;
};

// Enable mipmap filtering on shadows
const bool shadowHardwareFiltering = true;

const int shadowMapResolution = 1024; // Shadow map resolution [512 1024 1536 2048 2560 3072 3584 4096 4608 5120]
// Shadow noise tile
const int shdNoiseTile = 128;

// Lm noise tile
const int lmNoiseTile = 16;

// Shadow bias
const float shdBias = 0.02; // Don't go below it otherwise it'll mess up lighting
const float sunPathRotation = 45.0; // Light/sun/moon angle by degrees [-63.0 -54.0 -45.0 -36.0 -27.0 -18.0 -9.0 0.0 9.0 18.0 27.0 36.0 45.0 54.0 63.0]

uniform int isEyeInWater;

// Get frame time
uniform float frameTime;
uniform float frameTimeCounter;
// Get world time
uniform float adjustedTime;
uniform float day;
uniform float night;
uniform float dawnDusk;
uniform float twilight;
uniform float phase;

uniform float far;
uniform float near;

uniform ivec2 eyeBrightnessSmooth;

// Position uniforms
uniform vec3 cameraPosition;
uniform vec3 shadowLightPosition;

// Vec3 color uniforms
uniform vec3 fogColor;
uniform vec3 skyColor;

// Matrix uniforms
uniform mat4 gbufferModelView, gbufferModelViewInverse;
uniform mat4 gbufferProjection, gbufferProjectionInverse;

uniform mat4 shadowModelView, shadowModelViewInverse;
uniform mat4 shadowProjection, shadowProjectionInverse;

float eyeBrightFact = eyeBrightnessSmooth.y / 240.0;

float newDawnDusk = smoothstep(0.32, 0.96, dawnDusk);
float newTwilight = smoothstep(0.64, 0.96, twilight);

vec3 skyCol = mix(mix(SKY_COL_NIGHT, SKY_COL_DAY, day), SKY_COL_DAWN_DUSK, newDawnDusk);
vec3 lightCol = mix(mix(LIGHT_COL_NIGHT, LIGHT_COL_DAY, day), LIGHT_COL_DAWN_DUSK, newDawnDusk);