// Had to put this so Optifine can detect the option...
#ifdef SHD_ENABLE
#endif

#if !defined ENTITIES_GLOWING || defined SHD_ENABLE
	// Enable mipmap filtering on shadows
	const bool shadowHardwareFiltering = true;
	const int shadowMapResolution = 1024; // Shadow map resolution [512 1024 1536 2048 2560 3072 3584 4096 4608 5120]

	// Shadow bias
	const float shdBias = 0.025; // Don't go below the default value otherwise it'll mess up lighting
	const float sunPathRotation = 0.0; // Light angle [-63.0 -54.0 -45.0 -36.0 -27.0 -18.0 -9.0 0.0 9.0 18.0 27.0 36.0 45.0 54.0 63.0]

	// Shadow color
	uniform sampler2D shadowcolor0;

	// Shadow texture
	uniform sampler2DShadow shadowtex0;
	uniform sampler2DShadow shadowtex1;

	vec3 getShdTex(vec3 shdPos){
		float shd0 = shadow2D(shadowtex0, shdPos).x;
		float shd1 = shadow2D(shadowtex1, shdPos).x - shd0;
		
		#ifdef SHD_COL
			return texture2D(shadowcolor0, shdPos.xy).rgb * shd1 * (1.0 - shd0) + shd0;
		#else
			return vec3(shd0);
		#endif
	}

	vec3 getShdFilter(vec3 shdPos, float dither, float shdRcp){
		vec3 shdCol = getShdTex(shdPos);

		dither *= PI2;
		vec2 randVec = vec2(sin(dither), cos(dither)) * shdRcp;
		
		shdCol += getShdTex(vec3(shdPos.xy + randVec, shdPos.z));
		shdCol += getShdTex(vec3(shdPos.xy + -randVec, shdPos.z));

		return shdCol * 0.333;
	}

	// Shadow function
	vec3 getShdMapping(vec4 shdPos, vec3 normal, vec3 nLightPos, float dither, float ss){
		vec3 shdCol = vec3(0);
		float shdRcp = 1.0 / shadowMapResolution;

		// Light diffuse
		float lightDot = dot(normal, nLightPos) * (1.0 - ss) + ss;
		shdPos.xyz = distort(shdPos.xyz, shdPos.w) * 0.5 + 0.5;
		shdPos.z -= (shdBias + 0.125 * shdRcp) * squared(shdPos.w) / abs(lightDot);

		if(lightDot >= 0)
			#ifdef SHADOW_FILTER
				shdCol = getShdFilter(shdPos.xyz, dither, shdRcp);
			#else
				shdCol = getShdTex(shdPos.xyz);
			#endif

		return shdCol * saturate(lightDot) * (1.0 - newTwilight);
	}
#endif

float getDiffuse(vec3 normal, vec3 nLightPos, float ss){
	// Light diffuse
	float lightDot = dot(normal, nLightPos) * (1.0 - ss) + ss;

	return saturate(lightDot) * (1.0 - newTwilight);
}