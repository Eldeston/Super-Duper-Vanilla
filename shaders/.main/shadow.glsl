#version 120

uniform sampler2D tex;

#include "/lib/util.glsl"

IN vec2 texcoord;
IN vec4 color;
IN float getTransparent;

void main(){
    vec4 shdColor = texture2D(tex, texcoord) * color;

    gl_FragData[0] = shdColor;
}