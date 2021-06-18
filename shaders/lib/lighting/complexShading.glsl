// Complex lighting calculations all go here
vec3 complexShading(matPBR material, positionVectors posVector, vec3 dither){
	// Get positions
	vec3 reflectedEyePlayerPos = reflect(posVector.eyePlayerPos, material.normal_m);
	vec3 nLightPos = normalize(posVector.lightPos);
    vec3 nEyePlayerPos = normalize(-posVector.eyePlayerPos);
	vec3 lightVec = normalize(posVector.lightPos - posVector.eyePlayerPos);

	vec3 gBMVNorm = mat3(gbufferModelView) * material.normal_m;
	vec3 nDither = dither * 2.0 - 1.0;
	float smoothness = 1.0 - material.roughness_m;
	float sqrtSmoothness = sqrt(smoothness);

	material.albedo_t *= max(0.5, material.alpha_m);

	/* -Global illumination- */

	// Cave fix
	float caveFixShdFactor = smoothstep(0.2, 0.4, material.light_m.y) * (1.0 - eyeBrightFact) + eyeBrightFact;
	// Get direct light diffuse color
	float rainDiff = rainStrength * 0.5;
	vec3 directLight = (getShdMapping(posVector.shdPos, material.normal_m, nLightPos, dither.r, material.ss_m) * (1.0 - rainDiff) + smootherstep(material.light_m.y) * rainDiff) * lightCol * caveFixShdFactor;
	// Get globally illuminated sky
	vec3 GISky = ambientLighting + getSkyRender(material.normal_m, skyCol, lightCol, 0.0, 0.0, dither.r) * material.light_m.y * material.light_m.y;

	#ifdef SSGI
		// Get SSGI
		vec3 GIcol = getSSGICol(posVector.viewPos, posVector.screenPos, gBMVNorm, dither.xy);
	#else
		vec3 GIcol = vec3(0);
	#endif

	/* -Reflections- */

	// Get fresnel
    vec3 F0 = mix(vec3(0.04), material.albedo_t, material.metallic_m);
    vec3 fresnel = getFresnelSchlick(dot(material.normal_m, nEyePlayerPos), F0);
	// Get specular GGX
	vec3 specCol = getSpecGGX(nEyePlayerPos, nLightPos, lightVec, material.normal_m, fresnel, material.roughness_m) * directLight;

	#ifdef SSR
		vec4 SSRCol = getSSRCol(posVector.viewPos, posVector.screenPos, gBMVNorm, nDither, material.roughness_m);
	#else
		vec4 SSRCol = vec4(0);
	#endif
	
	// Get reflected sky
	float skyMask = pow(material.light_m.y, 1.0 / 4.0) * sqrtSmoothness;
    vec3 reflectedSkyRender = ambientLighting + getSkyRender(reflectedEyePlayerPos, skyCol, lightCol, skyMask, skyMask, dither.r) * material.light_m.y;

	// Mask reflections
    vec3 reflectCol = mix(reflectedSkyRender, SSRCol.rgb, SSRCol.a) * fresnel * sqrtSmoothness; // Will change this later...

	/* Calculate total lighting and return color */
	vec3 totalDiffuse = (directLight + GISky * material.ambient_m + GIcol + cubed(material.light_m.x) * BLOCK_LIGHT_COL * pow(material.ambient_m, 1.0 / 4.0)) * (1.0 - material.metallic_m) + material.emissive_m;
    return material.albedo_t * totalDiffuse + specCol + reflectCol;
}