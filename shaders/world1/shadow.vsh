#version 120

#include "/lib/settings.glsl"
#include "/lib/globalVar.glsl"
#include "/lib/util.glsl"

#include "/lib/lighting/shdDistort.glsl"

#include "/lib/transform/wave.glsl"

attribute vec2 mc_midTexCoord;

attribute vec4 mc_Entity;

OUT vec2 texcoord;
OUT vec4 color;

void main(){
    vec4 vertexPos = shadowModelViewInverse * (shadowProjectionInverse * ftransform());

    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    
    getWave(vertexPos.xyz, vertexPos.xyz + cameraPosition, texcoord, mc_midTexCoord, mc_Entity.x);

	gl_Position = shadowProjection * (shadowModelView * vertexPos);

	gl_Position.xyz = distort(gl_Position.xyz);

    #ifndef RENDER_FOLIAGE_SHD
        if(mc_Entity.x == 10001.0 || mc_Entity.x == 10002.0 || mc_Entity.x == 10003.0 || mc_Entity.x == 10004.0 || mc_Entity.x == 10007.0 || mc_Entity.x == 10011.0 || mc_Entity.x == 10013.0)
            gl_Position = vec4(10.0);
    #endif

    color = gl_Color;
}