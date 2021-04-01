/* Variable assembler variables, which allows me to get variables dynamically and easily every time I add a new variable */

void getMaterial(inout matPBR materialRaw, vec2 st){
    // Get raw materials
	vec3 matRaw0 = texture2D(colortex2, st).xyz;
	vec3 matRaw1 = texture2D(colortex3, st).xyz;
	vec3 matRaw2 = texture2D(colortex4, st).xyz;

    // Assign materials
	materialRaw.light_m = matRaw0.xy;
	materialRaw.albedo_t = texture2D(gcolor, st).rgb;
	materialRaw.normal_m = texture2D(colortex1, st).rgb * 2.0 - 1.0;
	#ifdef DEFAULT_MAT
		materialRaw.ss_m = matRaw0.z; materialRaw.metallic_m = matRaw1.x;
		materialRaw.emissive_m = matRaw1.y; materialRaw.roughness_m = matRaw1.z;
		materialRaw.ambient_m = matRaw2.x; materialRaw.alpha_m = matRaw2.z;
	#else
		materialRaw.ss_m = 0.0; materialRaw.metallic_m = 0.0;
		materialRaw.emissive_m = 0.0; materialRaw.roughness_m = 0.0;
		materialRaw.ambient_m = 1.0; materialRaw.alpha_m = 1.0;
	#endif
}

void getPosVectors(inout positionVectors posVec, vec2 st){
    // Assign positions
	posVec.screenPos = toScreenSpacePos(st);
	posVec.viewPos = toView(posVec.screenPos);
	posVec.playerPos = mat3(gbufferModelViewInverse) * posVec.viewPos;
	posVec.worldPos = posVec.playerPos + gbufferModelViewInverse[3].xyz;
	posVec.worldPos.y /= 128.0;
	posVec.lightPos = mat3(gbufferModelViewInverse) * shadowLightPosition;
	
	posVec.shdPos = toShadow(posVec.playerPos);
}