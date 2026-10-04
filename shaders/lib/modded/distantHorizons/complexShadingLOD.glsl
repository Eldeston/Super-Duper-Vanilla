#if WORLD_ID == 1
	#ifndef END_FLASH_UNIFORM_DECLARED
		#define END_FLASH_UNIFORM_DECLARED
		uniform float endFlashIntensity;
	#endif
#endif

#ifdef WORLD_LIGHT
void addLODShadowDiffuse(
	in dataPBR material, in float lodWeatherFade, in float skyLightSquared,
	inout vec3 totalIllumination, out bool isShadow, out float NLZ, out float shdCol, out vec3 sRGBLightCol
){
	#if WORLD_ID == 1
		#ifdef EPILEPSY_SAFETY
			float smoothFlashShd = 0.0;
		#else
			float smoothFlashShd = smoothstep(0.18, 0.50, endFlashIntensity) * endFlashIntensity;
		#endif
		sRGBLightCol = (LIGHT_COLOR_DATA_BLOCK0 * 1.5 + vec3(0.3, 0.1, 0.4)) * smoothFlashShd;
	#else
		// Get sRGB light color
		#ifndef FORCE_DISABLE_WEATHER
			sRGBLightCol = LIGHT_COLOR_DATA_BLOCK0 * (1.0 - lodWeatherFade);
		#else
			sRGBLightCol = LIGHT_COLOR_DATA_BLOCK0;
		#endif
		#if WORLD_ID == 0 && !defined EPILEPSY_SAFETY
			if(lightningFlash > 0.0){
				vec3 flashLight = mix(vec3(1.0), LIGHTNING_COLOR, 0.20) * (lightningFlash * 2.5);
				sRGBLightCol = mix(sRGBLightCol, flashLight, lightningFlash);
			}
		#endif
	#endif

	NLZ = dot(material.normal, vec3(shadowModelView[0].z, shadowModelView[1].z, shadowModelView[2].z));
	isShadow = NLZ > 0;

	// Calculate fake shadows
	#if WORLD_ID == 1
		shdCol = saturate(lmCoord.y / max(WORLD1_CUSTOM_SKYLIGHT, 0.1));
	#else
		shdCol = saturate(hermiteMix(0.8, 1.0, lmCoord.y)) * shdFade;
	#endif

	float dirLight = isShadow ? NLZ : 0.0;

	#ifdef SUBSURFACE_SCATTERING
		// Diffuse with simple SS approximation
		if(material.ss > 0) dirLight += (1.0 - dirLight) * material.ambient * material.ss * 0.5;
	#endif

	shdCol *= dirLight;

	#ifndef FORCE_DISABLE_WEATHER
		// Approximate rain diffusing light shadow
		float rainDirectAmount = 1.0 - lodWeatherFade * (1.0 - WEATHER_DIRECT_LIGHT);
		shdCol *= rainDirectAmount;

		float rainDiffuseAmount = lodWeatherFade * WEATHER_DIRECT_LIGHT;
		shdCol += rainDiffuseAmount * material.ambient * skyLightSquared * (1.0 - shdFade);
	#endif

	// Calculate and add shadow diffuse
	totalIllumination += toLinear(sRGBLightCol) * shdCol;
}
#endif

vec3 complexShadingLOD(in dataPBR material){
	// Calculate sky diffusion first, begining with the sky itself
	#ifndef FORCE_DISABLE_WEATHER
		#if WORLD_ID == 0
			#ifndef THUNDER_STRENGTH_DECLARED
				#define THUNDER_STRENGTH_DECLARED
				uniform float thunderStrength;
			#endif
			float lodWeatherFade = clamp(max(weatherFade, thunderStrength), 0.0, 1.0);
		#else
			float lodWeatherFade = weatherFade;
		#endif
		vec3 totalIllumination = mix(toLinear(SKY_COLOR_DATA_BLOCK), vec3(dot(toLinear(fogColor), vec3(0.2126, 0.7152, 0.0722))), lodWeatherFade);
	#else
		vec3 totalIllumination = toLinear(SKY_COLOR_DATA_BLOCK);
		const float lodWeatherFade = 0.0;
	#endif

	// Calculate thunder flash
	totalIllumination += toLinear(mix(vec3(1.0), LIGHTNING_COLOR, 0.20)) * lightningFlash;

	// Get block light squared
	float blockLightSquared = squared(lmCoord.x);
	// Get sky light squared
	float skyLightSquared = squared(lmCoord.y);

	// Occlude the appled sky and thunder flash calculation by sky light amount
	totalIllumination *= skyLightSquared;

	#if WORLD_ID == 1
		#ifdef EPILEPSY_SAFETY
			float smoothFlash = 0.0;
		#else
			float smoothFlash = smoothstep(0.18, 0.50, endFlashIntensity) * endFlashIntensity;
		#endif
		totalIllumination += toLinear(vec3(0.20, 0.12, 0.28)) * (smoothFlash * skyLightSquared);
		#ifdef END_BH_LIGHT
			if(END_BH_LIGHT > 0.0){
				const vec3 blackHoleDir = vec3(0.0, 0.6691306, -0.7431448);
				float NL_BH = max(0.0, dot(material.normal, blackHoleDir));
				float skyOcclusion = saturate(lmCoord.y / max(WORLD1_CUSTOM_SKYLIGHT, 0.1));
				totalIllumination += toLinear(LIGHT_COLOR_DATA_BLOCK0) * (END_BH_LIGHT * 1.5 * NL_BH * skyOcclusion);
			}
		#endif
	#endif

	// Lastly, calculate ambient lightning
	totalIllumination += toLinear(AMBIENT_LIGHTING + nightVision * 0.5);

	// Calculate block light
	totalIllumination += toLinear((float(material.emissive == 0) * 0.25 + 1.0) * blockLightSquared * blockLightColor);

	#ifdef WORLD_LIGHT
		bool isShadow;
		float NLZ, shdCol;
		vec3 sRGBLightCol;
		addLODShadowDiffuse(material, lodWeatherFade, skyLightSquared, totalIllumination, isShadow, NLZ, shdCol, sRGBLightCol);
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
		#if WATER_STYLE == 1
			if(isShadow && material.smoothness > 0.001 && material.metallic > 0.005 && NLZ > 0.0){
		#else
			if(isShadow && material.smoothness > 0.001 && NLZ > 0.0){
		#endif
			// Get specular GGX
			vec3 specCol = getSpecularBRDF(viewDir, material.normal, material.albedo.rgb, NLZ, NV, material.metallic, material.smoothness);
			totalLighting += min(specCol * shdCol * sRGBLightCol, vec3(5.0));
		}
	#endif

	return totalLighting;
}