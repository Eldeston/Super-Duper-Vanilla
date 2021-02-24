// Shadow texture
uniform sampler2DShadow shadowtex0;
uniform sampler2DShadow shadowtex1;

// Shadow color
uniform sampler2D shadowcolor0;

vec2 offSetShd[4] = vec2[4](
    vec2(0.00084),
    vec2(-0.00084),
    vec2(-0.00084, 0.00084),
    vec2(0.00084, -0.00084)
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

float getGGX(vec3 norm, vec3 halfVec, float roughness){
    float a2 = squared(roughness * roughness);
    float NdotH = max(dot(norm, halfVec), 0.0);
    float NdotH2 = NdotH * NdotH;
	
    float nom = a2;
    float denom = (NdotH2 * (a2 - 1.0) + 1.0);
    denom = PI * denom * denom;
	
    return nom / denom;
}

float getGeometrySchlickGGX(float NdotV, float roughness)
{
    float r = (roughness + 1.0);
    float k = (r * r) / 8.0;

    float num = NdotV;
    float denom = NdotV * (1.0 - k) + k;
	
    return num / denom;
}

float getGeometrySmith(vec3 norm, vec3 nViewPos, vec3 lightVec, float roughness)
{
    float NdotV = max(dot(norm, nViewPos), 0.0);
    float NdotL = max(dot(norm, lightVec), 0.0);
    float GGX2 = getGeometrySchlickGGX(NdotV, roughness);
    float GGX1 = getGeometrySchlickGGX(NdotL, roughness);
	
    return GGX1 * GGX2;
}

vec3 getFresnelSchlick(float cosTheta, vec3 F0){
	return F0 + (1.0 - F0) * pow(max(1.0 - cosTheta, 0.0), 5.0);
}

float getAmbient(matPBR material, positionVectors posVec, vec2 lm){
	return max((abs(material.normal_m.x) * 0.25 + material.normal_m.y * 0.25 + 0.75) * smootherstep(lm.y), 0.5);
}

const float rayDistance = 192.0; // Distance [64.0 80.0 96.0 112.0 128.0]
const int steps = 16; // Steps [16 32 48 64]

void binarySearch(inout vec3 result, vec3 refineDir){
	for(int refineStep = 0; refineStep < (steps / 8); refineStep++){
		vec2 screenQuery = toScreen(result).xy;
		if(screenQuery.x < 0.0 || screenQuery.y < 0.0 || screenQuery.x > 1.0 || screenQuery.y > 1.0) break;

		bool hit = result.z - (gbufferProjectionInverse[3].z / (gbufferProjectionInverse[2].w * (texture2D(depthtex0, screenQuery).r * 2.0 - 1.0) + gbufferProjectionInverse[3].w)) < 0.0;
		result += hit ? -refineDir : refineDir;
		refineDir *= 0.5;
	}
}

vec3 getScreenSpaceCoords(vec3 st, vec3 normal){
	vec3 startPos = toLocal(st);
	vec3 startDir = normalize(reflect(normalize(startPos), normal));

	vec3 endPos = startDir * rayDistance; // startPos + (startDir * maxDistance)
	vec3 result = startPos + endPos;
	vec3 hitPos = startPos;
	
	float stepSize = 1.0 / float(steps);
	bool hit = false;

	for(int x = 0; x < steps; x++){
		hitPos += endPos * stepSize;
		vec2 screenQuery = toScreen(hitPos).xy;
		if(screenQuery.x < 0.0 || screenQuery.y < 0.0 || screenQuery.x > 1.0 || screenQuery.y > 1.0) break;
		hit = hitPos.z - (gbufferProjectionInverse[3].z / (gbufferProjectionInverse[2].w * (texture2D(depthtex0, screenQuery).r * 2.0 - 1.0) + gbufferProjectionInverse[3].w)) < 0.0;

		if(hit) result = hitPos;
		if(hit) break;
	}

	binarySearch(result, startDir);

	result = toScreen(result);
	vec2 maskUv = result.xy - 0.5;
	float maskEdge = smoothstep(0.2, 0.0, length(maskUv * maskUv * maskUv));
	return vec3(result.xy, float(hit) * maskEdge * smoothstep(0.64, 0.56, normal.z));
}

/*
float getGodRays(vec2 st){
	vec4 pos = vec4(getScreenSpacePos(st), 1.0);
	pos.xyz = mat3(gbufferModelViewInverse) * toLocal(pos.xyz);
	float isRay = 0.0;
	int steps = 8;
	for(int x = 0; x < steps; x++){
		pos.xyz *= 0.8;
		pos = shadowProjection * (shadowModelView * vec4(pos.xyz, 1.0));
		float distortFactor = getDistortFactor(pos.xy);
		pos.xyz = distort(pos.xyz, distortFactor) * 0.5 + 0.5;
		isRay = shadow2D(shadowtex0, pos.xyz).x;
	}
	return isRay;
}
*/

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
			if(shd0 <= 1.0 || shdPos.w <= 1.0)
				shdCol += texture2D(shadowcolor0, shdPos.xy + shdOffSet).rgb * shd1 * (1.0 - shd0) + shd0;
		#else
			if(shd0 <= 1.0 || shdPos.w <= 1.0)
				shdCol += shd0;
		#endif
	}

	return shdCol * 0.25;
}

// Shadow function
vec3 getLighting(matPBR material, positionVectors posVec, vec2 lm){
	// Get ambient
	material.ambient_m *= getAmbient(material, posVec, lm);
	vec3 ambient = BLOCK_AMBIENT * material.ambient_m;
	// Get twilight amount
	float newTwilight = hermiteMix(0.64, 0.96, twilight);
	// Eye/View vector
	vec3 nViewPos = normalize(-posVec.viewPos);
	// Normalized light pos
	vec3 nLightPos = normalize(posVec.lightPos);
	// Light vector
	vec3 lightVec = normalize(posVec.lightPos - posVec.viewPos);
	
	// Light diffuse
	float lightDot = dot(material.normal_m, nLightPos) * (1.0 - material.ss_m) + material.ss_m;

	posVec.shdPos.xyz = distort(posVec.shdPos.xyz, posVec.shdPos.w) * 0.5 + 0.5;
	posVec.shdPos.z -= shdBias * squared(posVec.shdPos.w) / abs(lightDot);

	int shdSample = 4; // adding more doesn't give much of a difference except a slight performace decrease (limit 8)
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
				if(shd0 <= 1.0 || lightDot <= 1.0)
					shdCol = texture2D(shadowcolor0, posVec.shdPos.xy).rgb * shd1 * (1.0 - shd0) + shd0;
			#else
				if(shd0 <= 1.0 || lightDot <= 1.0)
					shdCol = shd0;
			#endif
		#endif
	}

	vec3 specShdMask = shdCol;
	shdCol = ambient * (1.0 - shdCol) + shdCol;

	shdCol = (1.0 - material.alpha_m) + shdCol * material.alpha_m;
	shdCol = mix(shdCol, ambient, newTwilight);

	vec3 spec = getSpecular(material.normal_m, nViewPos, lightVec, material.specular_m) * sqrt(sqrt(specShdMask)) * (1.0 - newTwilight);

	positionVectors reflectRefractVec;

	if(isEyeInWater == 1) reflectRefractVec.viewPos = refract(posVec.viewPos, material.normal_m, 1.0 / 1.52);
	else reflectRefractVec.viewPos = reflect(posVec.viewPos, material.normal_m);

	// Screenspace reflections
	vec2 screenUv = posVec.st + getRandVec(posVec.st, 128) * 0.001;
	vec3 sSRefUv = getScreenSpaceCoords(toScreenSpacePos(screenUv), mat3(gbufferModelView) * material.normal_m);
	vec3 sSRefCol = texture2D(colortex7, sSRefUv.xy).rgb;

	vec3 reflectRefractCol = getSkyRender(reflectRefractVec, skyCol, lightCol);
	float fresnel = getFresnel(material.normal_m, nViewPos, material.specular_m);
	
	// Refract
	if(isEyeInWater == 1) reflectRefractCol = mix(reflectRefractCol, spec, fresnel);
	// Reflect
	else reflectRefractCol = mix(spec, reflectRefractCol, fresnel);

	reflectRefractCol = mix(reflectRefractCol, sSRefCol, fresnel * sSRefUv.z * float(isEyeInWater == 0)) * float(material.specular_m > 0.0);

	float lightMap = min(lm.x * 1.2, 1.0);
	vec3 diffuse = (shdCol * (1.0 - material.emissive_m) + squared(material.emissive_m)) * (1.0 - lightMap) + BLOCK_LIGHT_COL * lightMap;

	return material.albedo_t * diffuse + reflectRefractCol;

	/*
	vec3 halfVec = normalize(lightVec + nViewPos);
	float roughness = min(1.0, 1.0 - 0.025);
	float metallic = 0.5;

	vec3 F0 = mix(vec3(0.04), material.albedo_t, metallic);
	vec3 F = getFresnelSchlick(max(dot(halfVec, nViewPos), 0.0), F0);

	float NDF = getGGX(material.normal_m, halfVec, roughness);
	float G = getGeometrySmith(material.normal_m, nViewPos, lightVec, roughness);
	vec3 numerator = NDF * G * F;
	float denominator = 4.0 * max(dot(material.normal_m, nViewPos), 0.0) * max(dot(material.normal_m, lightVec), 0.0);
	vec3 specular = numerator / max(denominator, 0.001);

	vec3 kS = F;
    vec3 kD = vec3(1.0) - kS;
	kD *= 1.0 - metallic;

	float NdotL = max(dot(material.normal_m, lightVec), 0.0);                
    vec3 Lo = (kD * material.albedo_t / PI + specular) * NdotL * specShdMask * 8.0;
	Lo = material.albedo_t * ambient + Lo;

	return Lo;
	*/
}

// Shadow function
vec3 getLighting(matPBR material, vec2 lm){
	vec3 ambient = BLOCK_AMBIENT * material.ambient_m;
	float lightMap = min(lm.x * 1.2, 1.0);
	vec3 diffuse = (ambient * (1.0 - material.emissive_m) + squared(material.emissive_m)) * (1.0 - lightMap) + BLOCK_LIGHT_COL * lightMap;

	return material.albedo_t * diffuse;
}