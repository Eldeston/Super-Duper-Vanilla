// Fragment GL version
#version 330 compatibility

#define GBUFFERS
#define SKY_BASIC
#define FRAGMENT

#include "/lib/settings.glsl"
#include "/lib/utility/common.glsl"

#include "world.glsl"
#include "/lib/worldResolver.glsl"
#include "/main/gbuffers/gbuffers_skybasic.glsl"