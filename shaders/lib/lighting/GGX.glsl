float getGGX(vec3 normal, vec3 halfVec, float roughness){
    float a = roughness * roughness;
    float a2 = a * a;
    
    float NdotH = max(dot(normal, halfVec), 0.0);
    float denom = (NdotH * NdotH * (a2 - 1.0) + 1.0);
	
    return a2 / (PI * denom * denom);
}

float getGeometrySchlickGGX(float NdotV, float roughness){
    float r = (roughness + 1.0);
    float k = (r * r) / 8.0;

    float num = NdotV;
    float denom = NdotV * (1.0 - k) + k;
	
    return num / denom;
}

float getGeometrySmith(float NdotV, float NdotL, float roughness){
    return getGeometrySchlickGGX(NdotV, roughness) * getGeometrySchlickGGX(NdotL, roughness);
}

vec3 getFresnelSchlick(float cosTheta, vec3 F0){
	return F0 + (1.0 - F0) * exp2(-9.28 * cosTheta);
    // F0 + (1.0 - F0) * pow(saturate(1.0 - cosTheta), 5.0);
}

vec3 getSpecGGX(vec3 nNegPlayerPos, vec3 nLightPos, vec3 lightVec, vec3 normal, vec3 fresnel, float roughness){
    float NdotV = max(dot(normal, nNegPlayerPos), 0.0);
    float NdotL = max(dot(normal, lightVec), 0.0);

    float NDF = getGGX(normal, normalize(nLightPos + nNegPlayerPos), roughness);
    float G = getGeometrySmith(NdotV, NdotL, roughness);
    vec3 numerator = NDF * G * fresnel;
    float denominator = 4.0 * NdotV * NdotL;

    return numerator / max(denominator, 0.001);
}

vec3 getSpecBRDF(vec3 V, vec3 L, vec3 N, vec3 fresnel, float roughness){  
    // Roughness remapping
    float alpha = roughness * roughness;
    float alphaSqr = alpha * alpha;

    // Halfway vector
    vec3 H = normalize(L + V);
    
    // Dot products
    float NH = max(dot(N, H), 0.0);    
    float LH = max(dot(L, H), 0.0);
    
    // D
    float denominator = NH * NH * (alphaSqr - 1.0) + 1.0;
    float distribution =  alphaSqr / (PI * denominator * denominator);

    // V
    float visibility = 1.0 / (LH + (1.0 / roughness));
    
    // Specular
    return distribution * fresnel * visibility;
}