void getPBR(inout matPBR material, vec2 screenCoord){
    // Get raw materials
	vec3 matRaw0 = texture2D(colortex3, screenCoord).xyz;

    // Assign materials
	material.albedo = texture2D(colortex2, screenCoord);
	material.normal = texture2D(colortex1, screenCoord).rgb * 2.0 - 1.0;
	
	material.metallic = matRaw0.x; material.emissive = matRaw0.y; material.smoothness = matRaw0.z;
}