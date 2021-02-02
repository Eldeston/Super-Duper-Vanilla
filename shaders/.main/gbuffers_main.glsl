#include "/lib/util.glsl"

#ifdef FRAGMENT
	#include "/lib/frameBuffer.glsl"
	
	uniform sampler2D lightmap;
	uniform sampler2D texture;

	IN vec2 lmcoord;
	IN vec2 texcoord;

	IN vec3 screenPos;
	IN vec3 norm;
	IN vec3 viewPos;

	IN vec4 glcolor;
	IN vec4 entity;

	IN mat3 TBN;

	void main(){
		vec2 randVec = getRandVec(screenPos.xy, lmNoiseTile);
		vec2 nLmCoord = lmcoord;

		#ifdef LIGHTMAP_NOISE
			nLmCoord = saturate(nLmCoord + randVec * LIGHTMAP_NOISE_INTENSITY);
		#endif

		vec4 color = texture2D(texture, texcoord);

		float maxCol = maxC(color); float satCol = rgb2hsv(color).y;
		float emissive = entity.x == 10001.0 ? maxCol
			: entity.x == 10002.0 ? satCol : 0.0;
		vec4 nGlcolor = glcolor * (1.0 - emissive) + glcolor.aaaa * emissive * emissive;

		#ifndef WHITE_MODE
			color *= nGlcolor;
		#else
			#ifdef WHITE_MODE_F
				color = color.aaaa * nGlcolor;
			#else
				color = color.aaaa;
			#endif
		#endif

		// Apply standard Minecraft light
		color *= texture2D(lightmap, nLmCoord) * (1.0 - emissive) + emissive;

	/* DRAWBUFFERS:012 */
		gl_FragData[0] = color; // buffer0
		gl_FragData[1] = vec4(nLmCoord, 0.0, 1.0); // buffer1
		gl_FragData[2] = vec4(0.5 + 0.5 * norm, 1.0); // buffer2
	}
#endif

#ifdef VERTEX
	uniform vec3 cameraPosition;

	uniform mat4 gbufferModelViewInverse;

	attribute vec4 mc_Entity;
	attribute vec4 at_tangent;

	OUT vec2 lmcoord;
	OUT vec2 texcoord;

	OUT vec3 screenPos;
	OUT vec3 norm;
	OUT vec3 viewPos;

	OUT vec4 glcolor;
	OUT vec4 entity;

	OUT mat3 TBN;
	OUT mat3 lmTBN;

	void main() {

		gl_Position = ftransform();
		viewPos = (gl_ModelViewMatrix * gl_Vertex).xyz;

		texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
		lmcoord  = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
		entity = mc_Entity;
		vec4 clipPos = gl_ProjectionMatrix * vec4(viewPos, 1.0);
		screenPos = clipPos.xyz / clipPos.w;

		//TBN matrix
		vec3 tangent = normalize(gl_NormalMatrix * at_tangent.xyz);
		vec3 binormal = normalize(gl_NormalMatrix * cross(at_tangent.xyz, gl_Normal) * at_tangent.w);

		norm = normalize(gl_NormalMatrix * gl_Normal);

		TBN = mat3(tangent, binormal, norm);
		glcolor = gl_Color;
	}
#endif