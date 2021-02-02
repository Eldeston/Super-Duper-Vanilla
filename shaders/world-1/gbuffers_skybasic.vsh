#version 120

#include "/lib/util.glsl"

OUT vec3 viewPos;
OUT vec4 starData; //rgb = star color, a = flag for weather or not this pixel is a star.

void main() {
	gl_Position = ftransform();
	viewPos = (gl_ModelViewMatrix * gl_Vertex).xyz;
	starData = vec4(gl_Color.rgb, float(gl_Color.r == gl_Color.g && gl_Color.g == gl_Color.b && gl_Color.r > 0.0));
}