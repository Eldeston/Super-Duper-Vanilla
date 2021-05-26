/* Variable assembler variables, which allows me to get variables dynamically and easily every time I add a new variable */

void getMaterial(inout matPBR material, vec2 st){
    // Get raw materials
	vec3 matRaw0 = texture2D(colortex2, st).xyz;
	vec3 matRaw1 = texture2D(colortex3, st).xyz;
	vec3 matRaw2 = texture2D(colortex4, st).xyz;

    // Assign materials
	material.light_m = matRaw0.xy;
	material.albedo_t = texture2D(gcolor, st).rgb;
	material.normal_m = mat3(gbufferModelViewInverse) * (texture2D(colortex1, st).rgb * 2.0 - 1.0);
	
	material.ss_m = matRaw0.z; material.metallic_m = matRaw1.x;
	material.emissive_m = matRaw1.y; material.roughness_m = matRaw1.z;
	material.ambient_m = matRaw2.x; material.alpha_m = matRaw2.z;
}

void getPosVectors(inout positionVectors posVec, vec2 st){
    // Assign positions
	posVec.screenPos = toScreenSpacePos(st);
	posVec.viewPos = toView(posVec.screenPos);
	posVec.eyePlayerPos = mat3(gbufferModelViewInverse) * posVec.viewPos;
	posVec.feetPlayerPos = posVec.eyePlayerPos + gbufferModelViewInverse[3].xyz;
	posVec.worldPos = posVec.feetPlayerPos + cameraPosition;
	posVec.worldPos.y /= 256.0; // Divide by max build height...
	posVec.lightPos = mat3(gbufferModelViewInverse) * shadowLightPosition;
	
	posVec.shdPos = toShadow(posVec.feetPlayerPos);
}