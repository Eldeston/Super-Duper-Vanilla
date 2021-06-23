void getPBR(inout matPBR material, vec2 screenCoord){
    // Get raw materials
	vec3 matRaw0 = texture2D(colortex2, screenCoord).xyz;
	vec3 matRaw1 = texture2D(colortex3, screenCoord).xyz;
	vec3 matRaw2 = texture2D(colortex4, screenCoord).xyz;

    // Assign materials
	material.albedo_t = texture2D(colortex7, screenCoord);
	material.normal_m = texture2D(colortex1, screenCoord).rgb * 2.0 - 1.0;
	material.light_m = matRaw0.xy;
	
	material.ss_m = matRaw0.z; material.metallic_m = matRaw1.x;
	material.emissive_m = matRaw1.y; material.roughness_m = matRaw1.z;
	material.ambient_m = matRaw2.x; material.alpha_m = matRaw2.z;
}