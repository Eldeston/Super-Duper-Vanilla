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
	specularMap = squared(specularMap);
	float spec = pow(max(dot(norm, halfVec), 0.0), 128.0 * (specularMap + 0.1)) * (specularMap + 0.1);
	return spec;
}

float getAmbient(matPBR material, positionVectors posVec, vec2 lm){
	return max((abs(material.normal_m.x) * 0.25 + material.normal_m.y * 0.25 + 0.75) * smootherstep(lm.y), 0.5);
}

const float rayDistance = 200.0; // Distance [64.0 80.0 96.0 112.0 128.0]
const int steps = 16; // Steps [16 32 48 64]

vec3 binarySearch(vec3 refineDir, vec3 result){
	for(int refineStep = 0; refineStep < (steps / 4); refineStep++){
		vec2 screenQuery = toScreen(result).xy;
		if(screenQuery.x < 0.0 || screenQuery.y < 0.0 || screenQuery.x > 1.0 || screenQuery.y > 1.0) break;

		float localQuery = gbufferProjectionInverse[3].z / (gbufferProjectionInverse[2].w * (texture2D(depthtex0, screenQuery).r * 2.0 - 1.0) + gbufferProjectionInverse[3].w);
		result += (result.z - localQuery) < 0.0 ? -refineDir : refineDir;
		refineDir *= 0.5;
	}
	return result;
}

vec3 getScreenSpaceCoords(vec3 st, vec3 normal){
	vec3 startPos = toLocal(st);
	vec3 startDir = normalize(reflect(normalize(startPos), normal));

	vec3 endPos = startDir * rayDistance; // startPos + (startDir * maxDistance)
	vec3 result = startPos + endPos;

	vec3 hitPos = startPos;
	if(result.x > 0.0 || result.y > 0.0 || result.x < 1.0 || result.y < 1.0){
		float stepSize = 1.0 / float(steps);
		for(int x = 0; x < steps; x++){
			hitPos += endPos * stepSize;
			vec2 screenQuery = toScreen(hitPos).xy;
			if(screenQuery.x < 0.0 || screenQuery.y < 0.0 || screenQuery.x > 1.0 || screenQuery.y > 1.0) break;
			float localQuery = gbufferProjectionInverse[3].z / (gbufferProjectionInverse[2].w * (texture2D(depthtex0, screenQuery).r * 2.0 - 1.0) + gbufferProjectionInverse[3].w);

			if((hitPos.z - localQuery) < 0.0){
				result = hitPos; break;
			}
		}

		result = binarySearch(startDir, result);
	}

	result = toScreen(result);
	vec2 maskUv = result.xy - 0.5;
	return vec3(result.xy, smoothstep(0.2, 0.0, length(maskUv * maskUv * maskUv)));
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
					shdCol = mix(ambient, vec3(1.0), texture2D(shadowcolor0, posVec.shdPos.xy).rgb * shd1) * (1.0 - shd0) + shd0;
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

	// Screenspace reflections
	vec2 screenUv = posVec.st; // + getRandVec(posVec.st, 128) / 256.0;
	vec3 sSRefUv = getScreenSpaceCoords(getScreenSpacePos(screenUv), mat3(gbufferModelView) * material.normal_m);
	vec3 sSRefCol = texture2D(colortex7, sSRefUv.xy).rgb;
	float sSRefMask = float(getSkyMask(sSRefUv.xy) != 1.0) * sSRefUv.z;

	vec3 reflectRefractCol = getSkyRender(reflectRefractVec, skyCol, lightCol);
	float fresnel = getFresnel(material.normal_m, nViewPos, material.specular_m);
	
	if(isEyeInWater == 1) // Refract
		reflectRefractCol = mix(reflectRefractCol, vec3(spec), fresnel);
	else // Reflect
		reflectRefractCol = mix(vec3(spec), reflectRefractCol, fresnel);

	reflectRefractCol = mix(reflectRefractCol, sSRefCol, fresnel * sSRefMask) * float(material.specular_m > 0.0);

	float lightMap = min(lm.x * 1.2, 1.0);
	vec3 diffuse = (shdCol * (1.0 - material.emissive_m) + squared(material.emissive_m)) * (1.0 - lightMap) + BLOCK_LIGHT_COL * lightMap;

	return material.albedo_t * diffuse + reflectRefractCol;
	//return reflectRefractCol * sSRefUv.zzz;
}

// Shadow function
vec3 getLighting(matPBR material, vec2 lm){
	vec3 ambient = BLOCK_AMBIENT * material.ambient_m;
	float lightMap = min(lm.x * 1.2, 1.0);
	vec3 diffuse = (ambient * (1.0 - material.emissive_m) + squared(material.emissive_m)) * (1.0 - lightMap) + BLOCK_LIGHT_COL * lightMap;

	return material.albedo_t * diffuse;
}