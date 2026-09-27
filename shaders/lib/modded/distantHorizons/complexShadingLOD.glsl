#if WORLD_ID == 1
	#ifndef END_FLASH_UNIFORM_DECLARED
		#define END_FLASH_UNIFORM_DECLARED
		uniform float endFlashIntensity;
	#endif
#endif

vec3 complexShadingLOD(in dataPBR material){
	// Calculate sky diffusion first, begining with the sky itself
	#ifndef FORCE_DISABLE_WEATHER
		vec3 totalIllumination = mix(toLinear(SKY_COLOR_DATA_BLOCK), vec3(dot(toLinear(fogColor), vec3(0.2126, 0.7152, 0.0722))), weatherFade);
	#else
		vec3 totalIllumination = toLinear(SKY_COLOR_DATA_BLOCK);
	#endif

	// Calculate thunder flash
	totalIllumination += lightningFlash;

	// Get block light squared
	float blockLightSquared = squared(lmCoord.x);
	// Get sky light squared
	float skyLightSquared = squared(lmCoord.y);

	// Occlude the appled sky and thunder flash calculation by sky light amount
	totalIllumination *= skyLightSquared;

	#if WORLD_ID == 1
		totalIllumination += toLinear(vec3(0.20, 0.12, 0.28)) * (endFlashIntensity * skyLightSquared);
	#endif

	// Lastly, calculate ambient lightning
	totalIllumination += toLinear(AMBIENT_LIGHTING + nightVision * 0.5);

	// Calculate block light
	totalIllumination += toLinear((float(material.emissive == 0) * 0.25 + 1.0) * blockLightSquared * blockLightColor);

	#ifdef WORLD_LIGHT
		#if WORLD_ID == 1
			vec3 sRGBLightCol = (LIGHT_COLOR_DATA_BLOCK0 * 1.5 + vec3(0.3, 0.1, 0.4)) * endFlashIntensity;
			#ifdef END_BH_LIGHT
				float NL_BH = dot(material.normal, vec3(0.0, 0.8660254, -0.5));
				if(END_BH_LIGHT > 0.0 && NL_BH > 0.0){
					float bhShd = saturate(hermiteMix(0.9, 1.0, lmCoord.y)) * material.ambient;
					totalIllumination += toLinear(LIGHT_COLOR_DATA_BLOCK0 * END_BH_LIGHT) * (bhShd * NL_BH);
				}
			#endif
		#else
			// Get sRGB light color
			vec3 sRGBLightCol = LIGHT_COLOR_DATA_BLOCK0;
		#endif

		float NLZ = dot(material.normal, vec3(shadowModelView[0].z, shadowModelView[1].z, shadowModelView[2].z));
		// also equivalent to:
		// vec3(0, 0, 1) * mat3(shadowModelView) = vec3(shadowModelView[0].z, shadowModelView[1].z, shadowModelView[2].z)
    	// shadowLightPosition is broken in other dimensions. The current is equivalent to:
    	// (mat3(gbufferModelViewInverse) * shadowLightPosition + gbufferModelViewInverse[3].xyz) * 0.01

		bool isShadow = NLZ > 0;

		// Calculate fake shadows
		float shdCol = saturate(hermiteMix(0.9, 1.0, lmCoord.y)) * shdFade;

		float dirLight = isShadow ? NLZ : 0.0;

		#ifdef SUBSURFACE_SCATTERING
			// Diffuse with simple SS approximation
			if(material.ss > 0) dirLight += (1.0 - dirLight) * material.ambient * material.ss * 0.5;
		#endif

		shdCol *= dirLight;

		#ifndef FORCE_DISABLE_WEATHER
			// Approximate rain diffusing light shadow
			float rainDirectAmount = 1.0 - weatherFade * (1.0 - WEATHER_DIRECT_LIGHT);
			shdCol *= rainDirectAmount;

			float rainDiffuseAmount = weatherFade * WEATHER_DIRECT_LIGHT;
			shdCol += rainDiffuseAmount * material.ambient * skyLightSquared * (1.0 - shdFade);
		#endif

		// Calculate and add shadow diffuse
		totalIllumination += toLinear(sRGBLightCol) * shdCol;
	#endif

	// Get view direction
	vec3 viewDir = -fastNormalize(vertexFeetPlayerPos);

	// Modified version of BSL's reflection PBR calculation
	// vec3 fresnel = (F0 + (1.0 - F0) * cosTheta) * smoothness
	// Fresnel calculation derived and optimized from this equation
	float NV = dot(material.normal, viewDir);
	float smoothCosTheta = NV > 0 ? exp2(-9.28 * NV) * material.smoothness : material.smoothness;
	float oneMinusCosTheta = material.smoothness - smoothCosTheta;

	if(material.metallic <= 0.9) totalIllumination *= 1.0 - (smoothCosTheta + material.metallic * oneMinusCosTheta);
	else totalIllumination *= 1.0 - material.smoothness;

	// Apply emissives
	totalIllumination += material.emissive * EMISSIVE_INTENSITY;

	vec3 totalLighting = material.albedo.rgb * totalIllumination;

	#if defined WORLD_LIGHT && defined SPECULAR_HIGHLIGHTS
		if(isShadow){
			// Get specular GGX
			vec3 specCol = getSpecularBRDF(viewDir, material.normal, material.albedo.rgb, NLZ, NV, material.metallic, material.smoothness);
			totalLighting += specCol * shdCol * sRGBLightCol;
		}
	#endif

	return totalLighting;
}