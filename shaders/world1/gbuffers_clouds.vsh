#version 120

#include "/lib/util.glsl"

OUT vec2 texcoord;
OUT vec3 norm;
OUT vec4 glcolor;

void main() {
	gl_Position = ftransform();

	norm = normalize(gl_NormalMatrix * gl_Normal);

	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	glcolor = gl_Color;
}