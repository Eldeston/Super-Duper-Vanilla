// Complex lighting calculations all go here
vec3 complexLighting(matPBR material, positionVectors posVector, vec3 dither){
	// Get positions
	vec3 reflectedPlayerPos = reflect(posVector.playerPos, material.normal_m);
	vec3 nLightPos = normalize(posVector.lightPos);
    vec3 nPlayerPos = normalize(-posVector.playerPos);
	vec3 lightVec = normalize(posVector.lightPos - posVector.playerPos);
	vec3 gBMVNorm = mat3(gbufferModelView) * material.normal_m;

	// Get light diffuse color
	vec3 diffuseCol = getShdMapping(material, posVector.shdPos, nLightPos, dither.r) * lightCol;
	// Get globally illuminated sky
	vec3 GISky = getSkyRender(material.normal_m, 0.0, skyCol, lightCol) * material.light_m.y;

	// Get fresnel
    vec3 F0 = mix(vec3(0.04), material.albedo_t, material.metallic_m);
    vec3 fresnel = getFresnelSchlick(dot(material.normal_m, nPlayerPos), F0);
	// Get specular GGX
	vec3 specCol = getSpecGGX(material, fresnel, nPlayerPos, nLightPos, lightVec) * diffuseCol;

	// Reflected direction
	vec3 rayDir = reflect(normalize(posVector.viewPos), gBMVNorm) * (1.0 + dither.r * squared(material.roughness_m * material.roughness_m));
	// Get reflected screenpos
    vec3 reflectedScreenPos = rayTraceScene(posVector.screenPos, posVector.viewPos, rayDir);

	// Previous frame reprojection from Chocapic13
	vec4 viewPosPrev = gbufferProjectionInverse * vec4(vec3(reflectedScreenPos.xy, texture2D(depthtex0, reflectedScreenPos.xy).x) * 2.0 - 1.0, 1);
	viewPosPrev /= viewPosPrev.w;
	viewPosPrev = gbufferModelViewInverse * viewPosPrev;

	vec4 prevPosition = viewPosPrev + vec4(cameraPosition - previousCameraPosition, 0);
	prevPosition = gbufferPreviousModelView * prevPosition;
	prevPosition = gbufferPreviousProjection * prevPosition;
	reflectedScreenPos.xy = prevPosition.xy / prevPosition.w * 0.5 + 0.5;

	// Get reflected sky
    vec3 reflectedSkyRender = getSkyRender(reflectedPlayerPos, maxC(diffuseCol), skyCol, lightCol) * sqrt(material.light_m.y);

	// Sample reflections
	vec3 SSRCol = texture2D(colortex5, reflectedScreenPos.xy).rgb;
	// Transform it back to HDR
	SSRCol = 1.0 / (1.0 - SSRCol) - 1.0;
	// Mask reflections
    vec3 reflectCol = mix(reflectedSkyRender, SSRCol, reflectedScreenPos.z);
    reflectCol = max(reflectCol, vec3(0)) * fresnel * squared(1.0 - material.roughness_m); // Will change this later next patch...

	material.albedo_t *= 1.0 - material.metallic_m;

	// return reflectCol;
    return material.albedo_t * (diffuseCol + (GISky + material.light_m.x * BLOCK_LIGHT_COL) * material.ambient_m + material.emissive_m) + specCol + reflectCol;
}