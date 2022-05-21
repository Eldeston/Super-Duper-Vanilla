#version 130

// For the use of texture2DGradARB in PBR.glsl
#extension GL_ARB_shader_texture_lod : enable

#define GBUFFERS
#define ENTITIES_GLOWING
#define FRAGMENT

#include "/lib/settings.glsl"
#include "/lib/utility/util.glsl"

#include "world.glsl"
#include "/main/gbuffers_entities_glowing.glsl"