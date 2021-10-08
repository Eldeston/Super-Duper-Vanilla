// Had to put this so Optifine can detect the option...
#ifdef SHD_ENABLE
#endif

#if !defined ENTITIES_GLOWING || defined SHD_ENABLE
	// Enable mipmap filtering on shadows
	const bool shadowHardwareFiltering = true;
	const int shadowMapResolution = 1024; // Shadow map resolution [512 1024 1536 2048 2560 3072 3584 4096 4608 5120]

	// Shadow bias
	const float shdBias = 0.025; // Don't go below the default value otherwise it'll mess up lighting
	const float sunPathRotation = 0.0; // Light angle [-60.0 -55.0 -50.0 -45.0 -40.0 -35.0 -30.0 -25.0 -20.0 -15.0 -10.0 -5.0 0.0 5.0 10.0 15.0 20.0 25.0 30.0 35.0 40.0 45.0 50.0 55.0 60.0]

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
	vec3 getShdMapping(vec3 shdPos, float dirLight, float dither){
		vec3 shdCol = vec3(0);

		if(dirLight > 0){
			float shdRcp = 1.0 / shadowMapResolution;
			
			float distortFactor = getDistortFactor(shdPos.xy);
			shdPos.xyz = distort(shdPos.xyz, distortFactor) * 0.5 + 0.5;
			shdPos.z -= (shdBias + 0.125 * shdRcp) * (distortFactor * distortFactor) / max(dirLight, 0.001);

			#ifdef SHADOW_FILTER
				shdCol = getShdFilter(shdPos.xyz, dither, shdRcp);
			#else
				shdCol = getShdTex(shdPos.xyz);
			#endif
		}

		return shdCol * (1.0 - newTwilight);
	}
#endif

float getDiffuse(float NL, float ss){
	// Light diffuse and subsurface scattering
	return saturate(NL * (1.0 - ss) + ss) * (1.0 - newTwilight);
}