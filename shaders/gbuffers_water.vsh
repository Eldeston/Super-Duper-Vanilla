#version 120

#include "/lib/settings.glsl"
#include "/lib/globalVar.glsl"
#include "/lib/util.glsl"

#include "/lib/frameBuffer.glsl"

attribute vec4 mc_Entity;
attribute vec4 at_tangent;

OUT vec2 lmcoord;
OUT vec2 texcoord;

OUT vec3 screenPos;
OUT vec3 norm;
OUT vec3 viewPos;
OUT vec3 worldPos;

OUT vec4 glcolor;
OUT vec4 entity;

OUT mat3 TBN;
OUT mat3 lmTBN;

void main(){

	gl_Position = ftransform();
	viewPos = mat3(gbufferModelViewInverse) * (gl_ModelViewMatrix * gl_Vertex).xyz;
	vec4 clipPos = gl_ProjectionMatrix * vec4(viewPos, 1.0);
	screenPos = clipPos.xyz / clipPos.w;

	vec3 camPos = (gbufferModelViewInverse)[3].xyz + cameraPosition;
	worldPos = viewPos + camPos;

	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	lmcoord  = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	entity = mc_Entity;

    //TBN matrix
	vec3 tangent = normalize(gl_NormalMatrix * at_tangent.xyz);
	vec3 binormal = normalize(gl_NormalMatrix * cross(at_tangent.xyz, gl_Normal) * sign(at_tangent.w));

	norm = normalize(gl_NormalMatrix * gl_Normal);

	TBN = mat3(tangent, binormal, norm);

	glcolor = gl_Color;
}