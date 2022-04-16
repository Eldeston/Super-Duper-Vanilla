#version 120

#ifdef FRAGMENT
    // For the use of texture2DGradARB in PBR.glsl
    #extension GL_ARB_shader_texture_lod : enable
#endif

#define GBUFFERS
#define HAND_WATER
#define FRAGMENT

#include "/lib/settings.glsl"
#include "/lib/utility/util.glsl"

#include "world.glsl"
#include "/main/gbuffers_hand_water.glsl"