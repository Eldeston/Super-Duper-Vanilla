#version 120

#include "/lib/util.glsl"

OUT vec4 texCoord;

void main(){
    gl_Position = ftransform();

    texCoord = gl_MultiTexCoord0;
}