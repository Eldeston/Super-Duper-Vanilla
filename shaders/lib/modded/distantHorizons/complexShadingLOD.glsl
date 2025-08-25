vec4 complexShadingLOD(in dataPBR material){
	// Calculate sky diffusion first, begining with the sky itself
	vec3 totalIllumination = toLinear(SKY_COLOR_DATA_BLOCK);

	// Calculate thunder flash
	totalIllumination += lightningFlash;

	// Get block light squared
	float blockLightSquared = squared(lmCoord.x);
	// Get sky light squared
	float skyLightSquared = squared(lmCoord.y);

	// Occlude the appled sky and thunder flash calculation by sky light amount
	totalIllumination *= skyLightSquared;

	// Lastly, calculate ambient lightning
	totalIllumination += toLinear(AMBIENT_LIGHTING + nightVision * 0.5);

	// Calculate block light
	totalIllumination += toLinear((float(material.emissive == 0) * 0.25 + 1.0) * blockLightSquared * blockLightColor);

	#ifdef WORLD_LIGHT
		// Get sRGB light color
		vec3 sRGBLightCol = LIGHT_COLOR_DATA_BLOCK0;

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

		float finalShadowCol = shdCol * dirLight;

		#ifndef FORCE_DISABLE_WEATHER
			// Approximate rain diffusing light shadow
			float rainDiffuseAmount = rainStrength * 0.5;
			finalShadowCol *= 1.0 - rainDiffuseAmount;

			finalShadowCol += rainDiffuseAmount * material.ambient * skyLightSquared * (1.0 - shdFade);
		#endif

		// Calculate and add shadow diffuse
		totalIllumination += toLinear(sRGBLightCol) * finalShadowCol;
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

	vec4 totalLighting = vec4(material.albedo.rgb * totalIllumination, material.albedo.a);

	#if defined WORLD_LIGHT && defined SPECULAR_HIGHLIGHTS
		if(isShadow){
			// Get specular GGX
			vec3 specCol = getSpecularBRDF(viewDir, material.normal, material.albedo.rgb, NLZ, NV, material.metallic, material.smoothness) * shdCol;
			totalLighting.rgb += sunMoonIntensitySqrd * specCol * sRGBLightCol;
			totalLighting.a = min(maxOf(specCol) + totalLighting.a, 1.0);
		}
	#endif

	return totalLighting;
}