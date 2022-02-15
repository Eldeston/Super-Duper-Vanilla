#version 120

// For the use of texture2DGradARB in PBR.glsl
#extension GL_ARB_shader_texture_lod : enable

#define GBUFFERS
#define HAND
#define FRAGMENT

#include "world.glsl"
#include "/main/gbuffers_hand.glsl"