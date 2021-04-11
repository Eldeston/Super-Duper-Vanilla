// Shadow texture
uniform sampler2DShadow shadowtex0;
uniform sampler2DShadow shadowtex1;

// Shadow color
uniform sampler2D shadowcolor0;

// Shadow bias
const float shdBias = 0.025; // Don't go below it otherwise it'll mess up lighting
const float offSetNumerator = 1.0;

vec2 offSetShd[4] = vec2[4](
    vec2(1.0 / shadowMapResolution),
    vec2(-1.0 / shadowMapResolution),
    vec2(-1.0, 1.0) / shadowMapResolution,
    vec2(1.0, -1.0) / shadowMapResolution
);

vec3 getShdFilter(vec4 shdPos){
	// Get random vector
	vec2 shdRandVec = getRandVec(shdPos.xy, shdNoiseTile);

	float shd0, shd1 = 0.0;
	vec3 shdCol = vec3(0.0);
	float lightDiff = saturate(shdPos.w);

	for(int i = 0; i < 4; i++){
		vec2 shdOffSet = shdRandVec * offSetShd[i];
		shd0 = min(shadow2D(shadowtex0, vec3(shdPos.xy + shdOffSet, shdPos.z)).x, lightDiff);
		shd1 = min(shadow2D(shadowtex1, vec3(shdPos.xy + shdOffSet, shdPos.z)).x, lightDiff) - shd0;

		#ifdef SHD_COL
			shdCol += texture2D(shadowcolor0, shdPos.xy + shdOffSet).rgb * shd1 * (1.0 - shd0) + shd0;
		#else
			shdCol += shd0;
		#endif
	}

	return shdCol * 0.25;
}

// Shadow function
vec3 getShdMapping(matPBR material, positionVectors posVec){
	// Get twilight amount
	float newTwilight = hermiteMix(0.64, 0.96, twilight);
	// Normalized light pos
	vec3 nLightPos = normalize(posVec.lightPos);
	// Light vector
	vec3 lightVec = normalize(posVec.lightPos - posVec.playerPos);

	vec3 ambient = BLOCK_AMBIENT;
	
	// Light diffuse
	float lightDot = dot(material.normal_m, nLightPos) * (1.0 - material.ss_m) + material.ss_m;

	posVec.shdPos.xyz = distort(posVec.shdPos.xyz, posVec.shdPos.w) * 0.5 + 0.5;
	posVec.shdPos.z -= shdBias * squared(posVec.shdPos.w) / abs(lightDot);

	vec3 shdCol = vec3(0.0);

	if(lightDot >= 0.0){
		#ifdef SHADOW_FILTER
			shdCol = getShdFilter(vec4(posVec.shdPos.xyz, lightDot));
		#else
			float lightDiff = saturate(lightDot);
			float shd0, shd1 = 0.0;

			shd0 = min(shadow2D(shadowtex0, posVec.shdPos.xyz).x, lightDiff);
			shd1 = min(shadow2D(shadowtex1, posVec.shdPos.xyz).x, lightDiff) - shd0;
			
			#ifdef SHD_COL
				shdCol = texture2D(shadowcolor0, posVec.shdPos.xy).rgb * shd1 * (1.0 - shd0) + shd0;
			#else
				shdCol = shd0;
			#endif
		#endif
	}
	shdCol = ambient * (1.0 - shdCol) + shdCol;
	shdCol = (1.0 - material.alpha_m) + shdCol * material.alpha_m;
	shdCol = mix(shdCol, ambient, newTwilight);

	float lightMap = min(material.light_m.x * 1.2, 1.0);
	shdCol = shdCol * (1.0 - material.emissive_m) + material.emissive_m * material.emissive_m;
	shdCol = mix(shdCol, BLOCK_LIGHT_COL, lightMap);

	return shdCol;
}