#include "/lib/util.glsl"

#ifdef FRAGMENT
	#include "/lib/frameBuffer.glsl"
	
	#include "/lib/lighting/shdDistort.glsl"
	#include "/lib/lighting/shadows.glsl"

	uniform float far;

	uniform vec3 fogColor;
	uniform vec3 skyColor;

	IN vec2 texcoord;

	IN vec4 entity;

	void main() {
		vec3 albedo = getAlbedo(texcoord);
		bool fogged = getFogged(texcoord);
		vec2 lm = getLightMap(texcoord);

		vec3 viewPos = getEyePlayerPos(texcoord, false).xyz;
		vec3 norm = normalize(mat3(gbufferModelViewInverse) * getNormal(texcoord));

		albedo = getDepth(texcoord) == 1.0 ? albedo
			: getLighting(entity, albedo, WORLD_AMBIENT1, LIGHT_COL1, viewPos, mat3(gbufferModelViewInverse) * shadowLightPosition, norm, texcoord, lm);

		float fog = smoothstep(far * 0.5, far * 0.75, length(viewPos));
		
		if(fogged) fog = smoothstep(far * 2.25, far * 2.75, length(viewPos));

		albedo = getDepth(texcoord) == 1.0 ? albedo : mix(albedo, fogColor, fog);

	/* DRAWBUFFERS:03 */
		gl_FragData[0] = vec4(albedo, 1.0); // gcolor
		gl_FragData[1] = vec4(albedo * smoothstep(BLOOM_THRESHOLD, BLOOM_AMOUNT, A_Saturation(albedo, 0.0).r), 1.0);
	}
#endif

#ifdef VERTEX
	attribute vec4 mc_Entity;

	OUT vec2 texcoord;

	OUT vec4 entity;

	void main() {
		gl_Position = ftransform();

		entity = mc_Entity;

		texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	}
#endif