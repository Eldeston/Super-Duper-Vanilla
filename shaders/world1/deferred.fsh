#version 120

/* Lighting and fog for opaques goes here */

#define END

#include "/lib/settings.glsl"
#include "/lib/globalVar.glsl"
#include "/lib/util.glsl"

#include "/lib/frameBuffer.glsl"

#include "/lib/lighting/shdDistort.glsl"
#include "/lib/transform/conversion.glsl"
#include "/lib/atmospherics/sky.glsl"
#include "/lib/atmospherics/fog.glsl"
#include "/lib/lighting/lighting.glsl"

// Must come in last
#include "/lib/transform/varAssembler.glsl"

IN vec2 texcoord;

void main(){
	float skyMask = getSkyMask(texcoord);
	float isSkyDepth = float(getDepth(texcoord) == 1.0);

	// Declare and get positions
	positionVectors posVector;
	getPosVectors(posVector, texcoord);

	// Declare and get materials
	matPBR materials;
	getMaterial(materials, texcoord);
	
	vec3 skyCol2 = getSkyRender(posVector, skyCol, lightCol);

	if(isSkyDepth != 1.0)
		materials.albedo_t = getLighting(materials, posVector, posVector.lm);

	materials.albedo_t = getFog(posVector, materials.albedo_t, skyCol2);

/* DRAWBUFFERS:0 */
	gl_FragData[0] = vec4(materials.albedo_t, 1.0); // gcolor
}