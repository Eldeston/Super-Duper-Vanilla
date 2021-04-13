vec3 complexLighting(matPBR material, vec3 shdCol, vec3 specCol){
    specCol *= shdCol;
    
    shdCol = BLOCK_AMBIENT * (1.0 - shdCol) + shdCol;
	shdCol = (1.0 - material.alpha_m) + shdCol * material.alpha_m;

	float lightMap = min(material.light_m.x * 1.2, 1.0);
	shdCol = shdCol * (1.0 - material.emissive_m) + material.emissive_m * material.emissive_m;
	shdCol = mix(shdCol, BLOCK_LIGHT_COL, lightMap);

    return material.albedo_t * shdCol + specCol;
}