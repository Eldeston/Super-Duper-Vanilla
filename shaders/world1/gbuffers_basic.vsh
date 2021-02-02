#version 120

varying vec2 lmcoord;
varying vec4 glcolor;

void main() {
	gl_Position = ftransform();
	lmcoord  = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	glcolor = gl_Color;
}