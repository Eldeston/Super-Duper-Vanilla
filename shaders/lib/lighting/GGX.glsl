float getFresnel(vec3 norm, vec3 nPlayerPos, float specularMap){
	float fresnel = 1.0 - max(dot(norm, nPlayerPos), 0.0);
	return pow(fresnel, specularMap * 5.0);
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

vec3 getSpecGGX(matPBR material, positionVectors posVec){
    vec3 nLightPos = normalize(posVec.lightPos);
    vec3 nPlayerPos = normalize(-posVec.playerPos);
    vec3 halfDir = normalize(nLightPos + nPlayerPos);
	vec3 lightVec = normalize(posVec.lightPos - posVec.playerPos);

    vec3 F0 = mix(vec3(0.04), material.albedo_t, material.metallic_m);
    vec3 F = getFresnelSchlick(max(dot(halfDir, nPlayerPos), 0.0), F0);

    float NDF = getGGX(material.normal_m, halfDir, material.roughness_m);
    float G = getGeometrySmith(material.normal_m, nPlayerPos, lightVec, material.roughness_m);
	vec3 numerator = NDF * G * F;
	float denominator = 4.0 * max(dot(material.normal_m, nPlayerPos), 0.0) * max(dot(material.normal_m, lightVec), 0.0);

    return numerator / max(denominator, 0.001);
}