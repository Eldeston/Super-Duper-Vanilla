void getPBR(inout matPBR material, vec2 screenCoord){
    // Get raw materials
	vec3 matRaw0 = texture2D(colortex3, screenCoord).xyz;
	vec3 matRaw1 = texture2D(colortex4, screenCoord).xyz;

    // Assign materials
	material.albedo_t = texture2D(colortex2, screenCoord);
	material.normal_m = texture2D(colortex1, screenCoord).rgb * 2.0 - 1.0;
	
	material.metallic_m = matRaw0.x; material.emissive_m = matRaw0.y; material.roughness_m = matRaw0.z;
	material.ambient_m = matRaw1.x;
}