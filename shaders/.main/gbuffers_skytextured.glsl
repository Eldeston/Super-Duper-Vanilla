#version 120

#include "/lib/frameBuffer.glsl"
#include "/lib/util.glsl"

uniform sampler2D texture;

uniform mat4 gbufferProjection;

IN vec2 texcoord;

IN vec4 glcolor;

void main() {
	vec4 color = texture2D(texture, texcoord) * glcolor;

/* DRAWBUFFERS:0 */
	gl_FragData[0] = color; //gcolor
}