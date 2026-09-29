/*
================================ /// Super Duper Vanilla v1.3.8 /// ================================

    Developed by Eldeston, presented by FlameRender (C) Studios.

    Voxy LOD Rendering Pipeline Module
    Provides fragment shading and PBR material output for Voxy far-distance voxel LOD terrain.

================================ /// Super Duper Vanilla v1.3.8 /// ================================
*/

#define VOXY_SHADING
#define NOISETEX_DECLARED
#define END_FLASH_UNIFORM_DECLARED

layout(location = 0) out vec4 sceneColOut;     // colortex4: HDR scene color
layout(location = 1) out vec3 normalDataOut;   // colortex1: Surface normal
layout(location = 2) out vec3 albedoDataOut;   // colortex2: Albedo color
layout(location = 3) out vec3 materialDataOut; // colortex3: Metallic, Smoothness, Mask

#include "/lib/settings.glsl"
#include "/lib/utility/common.glsl"
#include "/lib/PBR/dataStructs.glsl"
#include "/lib/utility/projectionFunctions.glsl"
#include "/lib/utility/noiseFunctions.glsl"

// Global position and lightmap variables accessed by complexShadingLOD and enviroPBR
vec2 lmCoord;
vec3 vertexFeetPlayerPos;
vec3 vertexWorldPos;

#ifdef WORLD_LIGHT
    #include "/lib/lighting/GGX.glsl"
#endif

#ifdef LAVA_NOISE
    #include "/lib/surface/lava.glsl"
#endif

#if defined ENVIRONMENT_PBR && !defined FORCE_DISABLE_WEATHER
    #include "/lib/PBR/enviroPBR.glsl"
#endif

#ifdef TRANSLUCENT
    #include "/lib/surface/water.glsl"
#endif

#include "/lib/modded/distantHorizons/complexShadingLOD.glsl"

// Direction normals mapped from Minecraft quad face index (0: -Y, 1: +Y, 2: -Z, 3: +Z, 4: -X, 5: +X)
const vec3 VOXY_FACE_NORMALS[6] = vec3[6](
    vec3(0.0, -1.0, 0.0), // DOWN
    vec3(0.0, 1.0, 0.0),  // UP
    vec3(0.0, 0.0, -1.0), // NORTH
    vec3(0.0, 0.0, 1.0),  // SOUTH
    vec3(-1.0, 0.0, 0.0), // WEST
    vec3(1.0, 0.0, 0.0)   // EAST
);

// Applies block properties, emissives, and materials from Iris block.properties IDs
void applyVoxyBlockProperties(inout dataPBR material, in uint blockId, in vec2 noiseUv, out float mask){
    mask = 0.0;

    // Emissive blocks (portals, fire, froglight, lanterns, torches, redstone, sculk, beacon)
    if((blockId >= 12100u && blockId <= 12101u) || (blockId >= 12300u && blockId <= 12303u) ||
       (blockId >= 12800u && blockId <= 12901u) || (blockId >= 13000u && blockId <= 13104u)){
        material.emissive = 1.0;
    }
    // Lava (block 11100)
    else if(blockId == 11100u){
        #ifdef LAVA_NOISE
            const float lavaTileSizeInv = 1.0 / LAVA_TILE_SIZE;
            float lavaNoise = saturate(max(getLavaNoise(noiseUv * lavaTileSizeInv) * 3.0, sumOf(material.albedo.rgb)) - 1.0);
            material.albedo.rgb = floor(material.albedo.rgb * lavaNoise * LAVA_BRIGHTNESS * 32.0) * 0.03125;
        #else
            material.albedo.rgb *= LAVA_BRIGHTNESS;
        #endif
        material.emissive = 1.0;
    }
    // Foliage & leaves subsurface scattering
    else if(blockId == 10000u){
        material.ss = 0.5;
    }
    // Metallic blocks
    else if(blockId >= 12400u && blockId <= 12403u){
        material.metallic = 0.9;
        material.smoothness = 0.7;
    }
    // Smooth blocks / polished surfaces / ice
    else if(blockId >= 12500u && blockId <= 12503u){
        material.smoothness = 0.85;
    }

    #ifdef TRANSLUCENT
        // Water
        if(blockId == 11102u){
            material.smoothness = 0.96;
            material.metallic = 0.04;
            float waterNoise = WATER_BRIGHTNESS;
            vec2 waterNoiseUv = vertexWorldPos.xz * waterTileSizeInv;
            #if defined WATER_NORMAL
                vec4 waterData = H2NWater(waterNoiseUv).xzyw;
                material.normal = fastNormalize(waterData.yxz * material.normal.x + waterData.xyz * material.normal.y + waterData.xzy * material.normal.z);
                #ifdef WATER_NOISE
                    waterNoise *= squared(0.128 + waterData.w * 0.5);
                #endif
            #elif defined WATER_NOISE
                float waterData = getCellNoise(waterNoiseUv);
                waterNoise *= squared(0.128 + waterData * 0.5);
            #endif
            material.albedo.rgb *= waterNoise;
            material.albedo.a = clamp(material.albedo.a, 0.6, 0.85);
            mask = 0.5;
        } else {
            material.smoothness = 0.90;
            material.metallic = 0.04;
            mask = 0.25;
        }
    #endif
}

void voxy_emitFragment(VoxyFragmentParameters parameters){
    // Reconstruct position in view and player space from depth using Voxy projection
    vec3 screenPos = vec3(gl_FragCoord.xy * vec2(pixelWidth, pixelHeight), gl_FragCoord.z);
    vec4 clipPos = vec4(screenPos * 2.0 - 1.0, 1.0);
    vec4 viewPosH = vxProjInv * clipPos;
    vec3 viewPos = viewPosH.xyz / viewPosH.w;
    float viewDist = length(viewPos);

    // Prevent overdraw against vanilla chunks
    if(far > viewDist + 4.0){ discard; return; }

    vec3 eyePlayerPos = mat3(gbufferModelViewInverse) * viewPos;
    vertexFeetPlayerPos = eyePlayerPos + gbufferModelViewInverse[3].xyz;
    vertexWorldPos = vertexFeetPlayerPos + cameraPosition;

    // Normal from cube face
    vec3 vertexNormal = VOXY_FACE_NORMALS[min(parameters.face, 5u)];

    // Decode Minecraft lightmap coordinates from Voxy's normalized UVs
    vec2 mcLight = saturate((parameters.lightMap - (0.5 / 16.0)) * (16.0 / 15.0)) * 240.0;
    #ifdef WORLD_CUSTOM_SKYLIGHT
        lmCoord = vec2(lightMapCoord(mcLight.x), WORLD_CUSTOM_SKYLIGHT);
    #else
        lmCoord = lightMapCoord(mcLight);
    #endif

    // Sampled color and biome tinting
    vec4 albedo = parameters.sampledColour * parameters.tinting;
    #ifndef TRANSLUCENT
        albedo.a = 1.0;
    #endif

    // Block texture UV for lava and block animations
    vec2 noiseUv = vertexWorldPos.zy * vertexNormal.x + vertexWorldPos.xz * vertexNormal.y + vertexWorldPos.xy * vertexNormal.z;

    #ifndef TRANSLUCENT
        vec2 noiseCol = texelFetch(noisetex, ivec2(noiseUv * 4.0) & 255, 0).xy;
        float lodNoise = (noiseCol.x + noiseCol.y) * 0.2 + 0.8;
        albedo.rgb = min(albedo.rgb * lodNoise, vec3(1.0));
    #endif

    #if COLOR_MODE == 1
        albedo.rgb = vec3(1.0);
    #elif COLOR_MODE == 2
        albedo.rgb = vec3(0.0);
    #elif COLOR_MODE == 3
        albedo.rgb = parameters.sampledColour.rgb * parameters.tinting.rgb;
    #endif

    // Initialize PBR material data
    dataPBR material;
    material.normal = vertexNormal;
    material.albedo = albedo;
    material.smoothness = 0.0;
    material.emissive = 0.0;
    material.metallic = 0.04;
    material.porosity = 0.0;
    material.ss = 0.0;
    material.parallaxShd = 1.0;
    material.ambient = 1.0;

    float mask;
    applyVoxyBlockProperties(material, parameters.customId, noiseUv, mask);

    material.albedo.rgb = toLinear(material.albedo.rgb);

    #if defined ENVIRONMENT_PBR && !defined FORCE_DISABLE_WEATHER
        if(material.emissive == 0.0) enviroPBR(material, vertexNormal);
    #endif

    // Compute deferred/forward complex LOD lighting
    vec3 shadedColor = complexShadingLOD(material);

    #if VOXY_DEBUG == 1
        shadedColor = mix(shadedColor, vec3(1.0, 0.2, 0.2), 0.35);
    #elif VOXY_DEBUG == 2
        shadedColor = vec3(lmCoord.x, lmCoord.y, 0.0);
    #elif VOXY_DEBUG == 3
        shadedColor = material.normal * 0.5 + 0.5;
    #endif

    // Output to G-Buffers
    sceneColOut = vec4(shadedColor, material.albedo.a);
    normalDataOut = material.normal;
    albedoDataOut = material.albedo.rgb;
    materialDataOut = vec3(material.metallic, material.smoothness, mask);
}
