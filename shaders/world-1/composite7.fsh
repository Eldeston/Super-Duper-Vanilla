#version 130

// For the use of texture2DLod in FXAA.glsl
#extension GL_ARB_shader_texture_lod : enable

#define COMPOSITE7
#define FRAGMENT

#include "/lib/settings.glsl"
#include "/lib/utility/util.glsl"

#include "world.glsl"
#include "/main/composite7.glsl"