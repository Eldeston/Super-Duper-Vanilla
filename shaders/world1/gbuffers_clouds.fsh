#version 120

#include "/lib/settings.glsl"
#include "/lib/globalVar.glsl"
#include "/lib/util.glsl"

#include "/lib/frameBuffer.glsl"

#include "/lib/lighting/shdDistort.glsl"
#include "/lib/transform/conversion.glsl"

uniform sampler2D texture;

IN vec2 texcoord;

IN vec3 norm;

IN vec4 glcolor;

void main(){
	vec3 normal = mat3(gbufferModelViewInverse) * norm;
	vec4 color = texture2D(texture, texcoord) * sqrt(glcolor);

/* DRAWBUFFERS:025 */
	gl_FragData[0] = color; // buffer0
	gl_FragData[1] = vec4(0.5 + 0.5 * normal, 1.0); // buffer2
	gl_FragData[2] = vec4(0.0, 1.0, 0.0, 1.0); // buffer5
}