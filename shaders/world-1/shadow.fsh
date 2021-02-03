#version 120

#include "/lib/util.glsl"

uniform sampler2D tex;

IN vec2 texcoord;
IN vec4 color;

void main(){
    vec4 shdColor = texture2D(tex, texcoord) * color;

    gl_FragData[0] = shdColor;
}