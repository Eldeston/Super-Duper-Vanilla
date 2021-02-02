#version 120

#include "/lib/settings.glsl"
#include "/lib/globalVar.glsl"
#include "/lib/util.glsl"

#include "/lib/lighting/shdDistort.glsl"

attribute vec4 mc_Entity;

OUT vec2 texcoord;
OUT vec4 color;
OUT float getTransparent;

float getWaterId(float materialId){
    if(
    materialId == 8.0 || // Flowing water
    materialId == 9.0 // Water
    ) return 1.0;
    else return 0.0;
}

void main(){
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    color = gl_Color;

    getTransparent = getWaterId(mc_Entity.x);

	gl_Position = ftransform();
	gl_Position.xyz = distort(gl_Position.xyz);

    #ifndef RENDER_FOLIAGE_SHD
        if(mc_Entity.x == 10000.0) gl_Position = vec4(10.0);
    #endif
}