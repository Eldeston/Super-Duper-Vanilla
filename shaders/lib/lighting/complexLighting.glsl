// Complex lighting calculations all go here
vec3 complexLighting(matPBR material, positionVectors posVector, vec3 dither){
	// Get positions
	vec3 reflectedPlayerPos = reflect(posVector.playerPos, material.normal_m);
	vec3 nLightPos = normalize(posVector.lightPos);
    vec3 nPlayerPos = normalize(-posVector.playerPos);
	vec3 lightVec = normalize(posVector.lightPos - posVector.playerPos);

	// Get light color
	vec3 lightCol = getShdMapping(material, posVector.shdPos, nLightPos) * lightCol;
	// Get reflected screenpos
    vec3 reflectedScreenPos = getScreenPosReflections(posVector.screenPos, posVector.viewPos, mat3(gbufferModelView) * material.normal_m, dither, material.roughness_m);
	// Get reflected sky
    vec3 reflectedSkyRender = getSkyRender(reflectedPlayerPos, 1.0, skyCol, lightCol) * material.light_m.y;
	// Get globally illuminated sky
	vec3 GISky = getSkyRender(material.normal_m, 0.0, skyCol, lightCol) * material.light_m.y;
	
	// Get fresnel
    vec3 F0 = mix(vec3(0.04), material.albedo_t, material.metallic_m);
    vec3 fresnel = getFresnelSchlick(dot(material.normal_m, nPlayerPos), F0);
	// Get specular GGX
	vec3 specCol = getSpecGGX(material, fresnel, nPlayerPos, nLightPos, lightVec) * lightCol;

	// Sample reflections
    vec3 reflectCol = mix(reflectedSkyRender, texture2D(colortex5, reflectedScreenPos.xy).rgb, reflectedScreenPos.z);
    reflectCol = max(reflectCol, vec3(0.0)) * fresnel * squared(1.0 - material.roughness_m); // Will change this later next patch...

	material.albedo_t *= 1.0 - material.metallic_m;

	// return reflectCol;
    return material.albedo_t * (lightCol + (GISky + material.light_m.x * BLOCK_LIGHT_COL) * material.ambient_m + material.emissive_m) + specCol + reflectCol;
}