// Fragment GL version
#version 330 compatibility

#define GBUFFERS
#define TEXTURED
#define FRAGMENT

#include "/lib/settings.glsl"
#include "/lib/utility/common.glsl"

#include "world.glsl"
#include "/lib/worldResolver.glsl"
#include "/main/gbuffers/gbuffers_textured.glsl"