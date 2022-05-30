#version 130

// For the use of texture2DLod for DOF
#extension GL_ARB_shader_texture_lod : enable

#define COMPOSITE3
#define FRAGMENT

#include "/lib/settings.glsl"
#include "/lib/utility/util.glsl"

#include "world.glsl"
#include "/main/composite3.glsl"