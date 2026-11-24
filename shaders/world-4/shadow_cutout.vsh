// Vertex GL version
#version 330 compatibility

#define SHADOW
#define CUTOUT
#define VERTEX

#include "/lib/settings.glsl"
#include "/lib/utility/common.glsl"

#include "world.glsl"
#include "/lib/dimension/worldResolver.glsl"
#include "/main/shadow/shadow_cutout.glsl"