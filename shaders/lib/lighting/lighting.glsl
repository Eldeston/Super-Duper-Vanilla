// Shadow texture
uniform sampler2DShadow shadowtex0;
uniform sampler2DShadow shadowtex1;

// Shadow color
uniform sampler2D shadowcolor0;

vec2 offSetShd[8] = vec2[8](
    vec2(0.00084),
    vec2(-0.00084),
    vec2(-0.00084, 0.00084),
    vec2(0.00084, -0.00084),
    vec2(0.00042),
    vec2(-0.00042),
    vec2(-0.00042, 0.00042),
    vec2(0.00042, -0.00042)
);

float getFresnel(vec3 norm, vec3 nViewPos, float specularMap){
	float fresnel = 1.0 - max(dot(norm, nViewPos), 0.0);
	return pow(fresnel, specularMap * 5.0);
}

float getSpecular(vec3 norm, vec3 nViewPos, vec3 lightVec, float specularMap){
    vec3 halfVec = normalize(lightVec + nViewPos);
	float spec = pow(max(dot(norm, halfVec), 0.0), 128.0 * (specularMap + 0.1)) * (specularMap * specularMap + 0.1);
	return spec;
}

float getAmbient(matPBR material, positionVectors posVec, vec2 lm){
	return max((abs(material.normal_m.x) * 0.25 + material.normal_m.y * 0.25 + 0.75) * smootherstep(lm.y), 0.5);
}

// Shadow function
vec3 getLighting(matPBR material, positionVectors posVec, vec2 lm){
	// Get ambient
	material.ambient_m *= getAmbient(material, posVec, lm);
	vec3 ambient = BLOCK_AMBIENT * material.ambient_m;
	// Get twilight amount
	float newTwilight = hermiteMix(0.64, 0.96, twilight);
	// Eye/ View vector
	vec3 nViewPos = normalize(-posVec.viewPos);
	// Normalized light pos
	vec3 nLightPos = normalize(posVec.lightPos);
	// Light vector
	vec3 lightVec = normalize(posVec.lightPos - posVec.viewPos);
	
	// Light diffuse
	float lightDot = dot(material.normal_m, nLightPos) * (1.0 - material.ss_m) + material.ss_m;

	posVec.shdPos.xyz = distort(posVec.shdPos.xyz, posVec.shdPos.w) * 0.5 + 0.5;
	posVec.shdPos.z -= shdBias * squared(posVec.shdPos.w) / abs(lightDot);
	
	float lightDiff = saturate(lightDot);

	// Get random vector
	vec2 shdRandVec = getRandVec(posVec.shdPos.xy, shdNoiseTile);

	int shdSample = 4; // adding more doesn't give much of a difference except a slight performace decrease (limit 8)
	float shd0, shd1 = 0.0;
	vec3 shdCol = vec3(0.0);

	if(lightDot > 0.0){
		#ifdef SHADOW_FILTER
			for(int i = 0; i < shdSample; i++){
				vec2 shdOffSet = shdRandVec * offSetShd[i];
				shd0 = min(shadow2D(shadowtex0, vec3(posVec.shdPos.xy + shdOffSet, posVec.shdPos.z)).x, lightDiff);
				shd1 = min(shadow2D(shadowtex1, vec3(posVec.shdPos.xy + shdOffSet, posVec.shdPos.z)).x, lightDiff) - shd0;
				
				#ifdef SHD_COL
					if(shd0 <= 1.0 || lightDot <= 1.0)
						shdCol += mix(ambient, vec3(1.0), texture2D(shadowcolor0, posVec.shdPos.xy + shdOffSet).rgb * shd1) * (1.0 - shd0) + shd0;
				#else
					if(shd0 <= 1.0 || lightDot <= 1.0)
						shdCol += ambient * (1.0 - shd0) + shd0;
				#endif
			}
			// Divide by the amount of samples
			shdCol /= shdSample;
		#else
			shd0 = min(shadow2D(shadowtex0, posVec.shdPos.xyz).x, lightDiff);
			shd1 = min(shadow2D(shadowtex1, posVec.shdPos.xyz).x, lightDiff) - shd0;
			#ifdef SHD_COL
				if(shd0 <= 1.0 || lightDot <= 1.0)
					shdCol = mix(ambient, vec3(1.0), texture2D(shadowcolor0, posVec.shdPos.xy + shdOffSet).rgb * shd1) * (1.0 - shd0) + shd0;
			#else
				if(shd0 <= 1.0 || lightDot <= 1.0)
					shdCol = ambient * (1.0 - shd0) + shd0;
			#endif
		#endif
	}else{
		shdCol = ambient;
	}
	shdCol = (1.0 - material.alpha_m) + shdCol * material.alpha_m;
	shdCol = mix(shdCol, ambient, newTwilight);

	float spec = getSpecular(material.normal_m, nViewPos, lightVec, material.specular_m) * sqrt(sqrt(shd0)) * (1.0 - newTwilight);

	positionVectors reflectRefractVec;

	if(isEyeInWater == 1)
		reflectRefractVec.viewPos = refract(posVec.viewPos, material.normal_m, 1.0 / 1.52);
	else
		reflectRefractVec.viewPos = reflect(posVec.viewPos, material.normal_m);

	vec3 reflectRefractCol = getSkyRender(reflectRefractVec, skyCol, lightCol) * ambient * material.specular_m;
	float fresnel = getFresnel(material.normal_m, nViewPos, material.specular_m);
	
	if(isEyeInWater == 1)
		reflectRefractCol = mix(reflectRefractCol, vec3(spec), fresnel);
	else
		reflectRefractCol = mix(vec3(spec), reflectRefractCol, fresnel);

	float emissive = material.emissive_m;
	float lightMap = min(lm.x * 1.2, 1.0);
	vec3 diffuse = (shdCol * (1.0 - emissive) + squared(emissive)) * (1.0 - lightMap) + BLOCK_LIGHT_COL * lightMap;

	return material.albedo_t * diffuse + reflectRefractCol;
}

// Shadow function
vec3 getLighting(matPBR material, vec2 lm){
	vec3 ambient = BLOCK_AMBIENT * material.ambient_m;
	float emissive = material.emissive_m;
	float lightMap = min(lm.x * 1.2, 1.0);
	vec3 diffuse = (ambient * (1.0 - emissive) + squared(emissive)) * (1.0 - lightMap) + BLOCK_LIGHT_COL * lightMap;

	return material.albedo_t * diffuse;
}