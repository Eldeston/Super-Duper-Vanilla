#version 120

/* Volumetric lighting goes here */

#include "/lib/settings.glsl"
#include "/lib/globalVar.glsl"
#include "/lib/util.glsl"

#include "/lib/frameBuffer.glsl"

#include "/lib/lighting/shdDistort.glsl"
#include "/lib/transform/conversion.glsl"
#include "/lib/atmospherics/sky.glsl"
#include "/lib/atmospherics/fog.glsl"
#include "/lib/lighting/lighting.glsl"

IN vec2 texcoord;

void main(){
	vec3 albedo = texture2D(gcolor, texcoord).rgb;

	albedo += lightCol * getGodRays(texcoord);

/* DRAWBUFFERS:0 */
	gl_FragData[0] = vec4(albedo, 1.0); //gcolor
}