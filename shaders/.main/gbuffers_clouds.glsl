#version 120

#include "/lib/util.glsl"

uniform sampler2D texture;

IN vec2 texcoord;
IN vec3 norm;
IN vec4 glcolor;

void main() {
	vec4 color = texture2D(texture, texcoord) * glcolor;

/* DRAWBUFFERS:02 */
	gl_FragData[0] = color; // buffer0
	gl_FragData[1] = vec4(0.5 + 0.5 * norm, 1.0); // buffer2
}