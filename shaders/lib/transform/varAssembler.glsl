/* Variable assembler variables, which allows me to get variables dynamically and easily every time I add a new variable */

void getMaterial(inout matPBR materialRaw, vec2 st){
    // Get raw materials
	vec3 matRaw0 = texture2D(colortex4, st).xyz;
	vec3 matRaw1 = texture2D(colortex5, st).xyz;

    // Assign materials
	materialRaw.albedo_t = texture2D(gcolor, st).rgb;
	materialRaw.normal_m = getNormal(st);
	materialRaw.alpha_m = matRaw1.x;
	#ifdef DEFAULT_MAT
		materialRaw.specular_m = matRaw0.x; materialRaw.ss_m = matRaw0.y;
		materialRaw.emissive_m = matRaw0.z; materialRaw.ambient_m = matRaw1.y + getSkyMask(st);
	#else
		materialRaw.specular_m = 0.0; materialRaw.ss_m = 0.0;
		materialRaw.emissive_m = 0.0; materialRaw.ambient_m = 1.0;
	#endif
}

void getPosVectors(inout positionVectors posVec, vec2 st){
    // Assign positions
	posVec.st = st;
    posVec.lm = getLightMap(st);
	posVec.screenPos = toScreenSpacePos(st);
	posVec.localPos = toLocal(posVec.screenPos);
	posVec.viewPos = mat3(gbufferModelViewInverse) * posVec.localPos.xyz;
	posVec.worldPos = posVec.viewPos + gbufferModelViewInverse[3].xyz;
	posVec.worldPos.y /= 128.0;
	posVec.lightPos = mat3(gbufferModelViewInverse) * shadowLightPosition;

	posVec.shdPos = toShadow(vec4(posVec.viewPos, 1.0));
}