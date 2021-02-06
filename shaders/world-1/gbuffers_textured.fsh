#version 120

#include "/lib/settings.glsl"
#include "/lib/globalVar.glsl"
#include "/lib/util.glsl"

#include "/lib/frameBuffer.glsl"

#include "/lib/lighting/shdDistort.glsl"
#include "/lib/transform/conversion.glsl"

uniform sampler2D lightmap;
uniform sampler2D texture;

IN vec2 lmcoord;
IN vec2 texcoord;

IN vec3 screenPos;
IN vec3 norm;
IN vec3 viewPos;
IN vec3 worldPos;

IN vec4 glcolor;
IN vec4 entity;

IN mat3 TBN;

void main(){
	vec2 randVec = getRandVec(screenPos.xy, lmNoiseTile);
	vec2 nLmCoord = squared(lmcoord);

	vec3 normal = mat3(gbufferModelViewInverse) * norm;

	#ifdef LIGHTMAP_NOISE
		nLmCoord = saturate(nLmCoord + randVec * LIGHTMAP_NOISE_INTENSITY);
	#endif

	vec4 color = texture2D(texture, texcoord);

	#ifndef WHITE_MODE
		color.rgb *= glcolor.rgb;
	#else
		#ifdef WHITE_MODE_F
			color.rgb = color.aaa * glcolor.rgb;
		#else
			color.rgb = color.aaa;
		#endif
	#endif

	// Apply standard Minecraft light
	color.rgb *= texture2D(lightmap, nLmCoord).rgb;

/* DRAWBUFFERS:01245 */
	gl_FragData[0] = color; // buffer0
	gl_FragData[1] = vec4(nLmCoord, 0.0, 1.0); // buffer1
	gl_FragData[2] = vec4(0.5 + 0.5 * normal, 1.0); // buffer2
	gl_FragData[3] = vec4(0.0, 0.5, 0.0, 1.0); // buffer4
	gl_FragData[4] = vec4(1.0, 1.0, 0.0, 1.0); // buffer5
}