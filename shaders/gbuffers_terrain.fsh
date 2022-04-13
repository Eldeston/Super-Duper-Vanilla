#version 120

#ifdef FRAGMENT
    // For the use of texture2DGradARB in PBR.glsl
    #extension GL_ARB_shader_texture_lod : enable
#endif

#define GBUFFERS
#define TERRAIN
#define FRAGMENT

#include "world.glsl"
#include "/lib/settings.glsl"
#include "/lib/utility/util.glsl"
#include "/main/gbuffers_terrain.glsl"