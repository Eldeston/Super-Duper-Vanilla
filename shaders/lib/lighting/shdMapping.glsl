// Enable filtering on shadows
const int shadowMapResolution = 1024; // Shadow map resolution. Increase for more resolution at the cost of performance. [512 1024 1536 2048 2560 3072 3584 4096 4608 5120 5632 6144 6656 7168 7680 8192]
const bool shadowHardwareFiltering = true; // Free slightly better filtering

const float shadowDistance = 128.0; // Shadow distance. Increase to stretch the shadow map to farther distances in blocks. It's recommended to match this setting with your render distance and increase your shadow map resolution. [32.0 64.0 96.0 128.0 160.0 192.0 224.0 256.0 288.0 320.0 352.0 384.0 416.0 448.0 480.0 512.0 544.0 576.0 608.0 640.0 672.0 704.0 736.0 768.0 800.0 832.0 864.0 896.0 928.0 960.0 992.0 1024.0]
const float shadowDistanceRenderMul = 1.0; // Hardcoded to be always 1.0 for maximum optimization.
const float entityShadowDistanceMul = 0.5; // Renders the entity shadows at half shadowDistance. Iris only.

// Shadow opaque
uniform sampler2DShadow shadowtex0;

#ifdef SHADOW_COLOR
	// Shadow w/o translucents
	uniform sampler2DShadow shadowtex1;

	// Shadow color
	uniform sampler2D shadowcolor0;
#endif

vec3 getShdCol(in vec3 shdPos){
	#ifdef SHADOW_COLOR
		// Sample shadows
		float shd0 = textureLod(shadowtex0, shdPos, 0);
		// If not in shadow, return "white"
		if(shd0 == 1) return vec3(1);

		// Sample opaque only shadows
		float shd1 = textureLod(shadowtex1, shdPos, 0);
		// If not in shadow return full shadow color
		if(shd1 != 0) return texelFetch(shadowcolor0, ivec2(shdPos.xy * shadowMapResolution), 0).rgb * shd1 * (1.0 - shd0) + shd0;
		// Otherwise, return "black"
		return vec3(0);
	#else
		// Sample shadows and return directly
		return vec3(textureLod(shadowtex0, shdPos, 0));
	#endif
}

vec3 getShdCol(in vec3 shdPos, in float dither){
	vec2 randVec = vec2(cos(dither), sin(dither)) / shadowMapResolution;

	#if ANTI_ALIASING >= 2
		return getShdCol(vec3(shdPos.xy + randVec, shdPos.z));
	#else
		return (getShdCol(vec3(shdPos.xy + randVec, shdPos.z)) + getShdCol(vec3(shdPos.xy - randVec, shdPos.z))) * 0.5;
	#endif
}