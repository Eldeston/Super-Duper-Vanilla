#version 120

#include "/lib/util.glsl"

OUT vec2 texcoord;

void main() {
	gl_Position = ftransform();

	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
}