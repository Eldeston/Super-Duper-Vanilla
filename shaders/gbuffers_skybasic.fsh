#version 120

#include "/lib/settings.glsl"
#include "/lib/globalVar.glsl"
#include "/lib/util.glsl"

#include "/lib/frameBuffer.glsl"

IN vec3 viewPos;
IN vec4 starData; //rgb = star color, a = flag for weather or not this pixel is a star.

void main(){
/* DRAWBUFFERS:01 */
	gl_FragData[0] = vec4(0.0, 0.0, 0.0, 1.0); //gcolor
	gl_FragData[1] = vec4(0.0, 0.0, 1.0, 1.0); //buffer1
}