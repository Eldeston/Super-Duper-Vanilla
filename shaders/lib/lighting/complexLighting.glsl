// Complex lighting calculations all go here
vec3 complexLighting(matPBR material, positionVectors posVector, vec3 shdCol, vec3 dither){
	vec3 reflectedPlayerPos = reflect(posVector.playerPos, material.normal_m);
	vec3 nLightPos = normalize(posVector.lightPos);
    vec3 nPlayerPos = normalize(-posVector.playerPos);
	vec3 lightVec = normalize(posVector.lightPos - posVector.playerPos);
    
    shdCol = BLOCK_AMBIENT * (1.0 - shdCol) + shdCol;
	shdCol = (1.0 - material.alpha_m) + shdCol * material.alpha_m;

	float lightMap = min(material.light_m.x * 1.2, 1.0);
	shdCol = shdCol * (1.0 - material.emissive_m) + material.emissive_m * material.emissive_m;
	shdCol = mix(shdCol, BLOCK_LIGHT_COL, lightMap);

	// Get reflected screenpos
    vec3 reflectedScreenPos = getScreenPosReflections(posVector.screenPos, mat3(gbufferModelView) * material.normal_m, dither, material.roughness_m);
	// Get reflected sky
    vec3 reflectedSkyRender = getSkyRender(reflectedPlayerPos, 1.0, skyCol, lightCol) * material.light_m.y;

	// Get fresnel
    vec3 F0 = mix(vec3(0.04), material.albedo_t, material.metallic_m);
    vec3 fresnel = getFresnelSchlick(dot(material.normal_m, nPlayerPos), F0);

	// Get specular GGX
	vec3 specCol = getSpecGGX(material, fresnel, nPlayerPos, nLightPos, lightVec) * shdCol;

	// Apply reflections
    vec3 reflectCol = mix(reflectedSkyRender, texture2D(colortex6, reflectedScreenPos.xy).rgb, reflectedScreenPos.z);
    reflectCol = reflectCol * fresnel * (1.0 - material.roughness_m); // Will change this later next patch

    return material.albedo_t * shdCol + specCol + reflectCol;
}