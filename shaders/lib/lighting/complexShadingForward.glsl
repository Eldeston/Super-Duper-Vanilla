vec4 complexShadingGbuffers(matPBR material, positionVectors posVector, vec3 dither){
	// Get positions
	vec3 reflectedEyePlayerPos = reflect(posVector.eyePlayerPos, material.normal_m);
	vec3 nLightPos = normalize(posVector.lightPos);
    vec3 nEyePlayerPos = normalize(-posVector.eyePlayerPos);
	vec3 lightVec = normalize(posVector.lightPos - posVector.eyePlayerPos);

	float smoothness = 1.0 - material.roughness_m;
	float sqrtSmoothness = sqrt(smoothness);

	// Cave fix
	float caveFixShdFactor = smoothstep(0.2, 0.4, material.light_m.y) * (1.0 - eyeBrightFact) + eyeBrightFact;
	// Get direct light diffuse color
	float rainDiff = rainStrength * 0.5;
	vec3 directLight = (getShdMapping(posVector.shdPos, material.normal_m, nLightPos, dither.r, material.ss_m) * (1.0 - rainDiff) + smootherstep(material.light_m.y) * rainDiff) * lightCol * caveFixShdFactor;
	// Get globally illuminated sky
	vec3 GISky = ambientLighting + getSkyRender(material.normal_m, skyCol, lightCol, 0.0, 0.0, dither.r) * material.light_m.y * material.light_m.y;

	// Get fresnel
    vec3 F0 = mix(vec3(0.04), material.albedo_t.rgb, material.metallic_m);
    vec3 fresnel = getFresnelSchlick(dot(material.normal_m, nEyePlayerPos), F0);
	// Get specular GGX
	vec3 specCol = getSpecGGX(nEyePlayerPos, nLightPos, lightVec, material.normal_m, fresnel, material.roughness_m) * directLight;

	// Get reflected sky
	float skyMask = pow(material.light_m.y, 1.0 / 4.0) * sqrtSmoothness;
    vec3 reflectedSkyRender = ambientLighting + getSkyRender(reflectedEyePlayerPos, skyCol, lightCol, skyMask, skyMask, dither.r) * material.light_m.y;

	// Mask reflections
    vec3 reflectCol = reflectedSkyRender * fresnel * sqrtSmoothness; // Will change this later...

	vec3 totalDiffuse = (directLight + GISky * material.ambient_m + cubed(material.light_m.x) * BLOCK_LIGHT_COL * pow(material.ambient_m, 1.0 / 4.0)) * (1.0 - material.metallic_m) + material.emissive_m;
	return vec4(material.albedo_t.rgb * totalDiffuse + specCol + reflectCol, material.albedo_t.a);
}