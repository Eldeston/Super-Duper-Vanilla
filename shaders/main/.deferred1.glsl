#include "/lib/util.glsl"
#include "/lib/structs.glsl"
#include "/lib/settings.glsl"
#include "/lib/globalVar.glsl"

#include "/lib/globalSamplers.glsl"
#include "/lib/lighting/shdDistort.glsl"
#include "/lib/conversion.glsl"

#include "/lib/atmospherics/fog.glsl"
#include "/lib/atmospherics/sky.glsl"

#include "/lib/lighting/GGX.glsl"
#include "/lib/lighting/shdMapping.glsl"

#include "/lib/raymarching/rayTracer.glsl"
#include "/lib/raymarching/volLighting.glsl"

#include "/lib/lighting/SSGI.glsl"
#include "/lib/lighting/SSR.glsl"

#include "/lib/lighting/complexLighting.glsl"

#include "/lib/varAssembler.glsl"

INOUT vec2 texcoord;

#ifdef VERTEX
    void main(){
        gl_Position = ftransform();
        texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    }
#endif

#ifdef FRAGMENT
    void main(){
    }
#endif