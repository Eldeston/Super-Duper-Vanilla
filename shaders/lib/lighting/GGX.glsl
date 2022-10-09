vec3 getFresnelSchlick(vec3 F0, float cosTheta){
    // Fast and more but not totally accurate fresnel
	return F0 + (1.0 - F0) * cosTheta;
}

float getFresnelSchlick(float F0, float cosTheta){
    // Fast and more but not totally accurate fresnel
	return F0 + (1.0 - F0) * cosTheta;
}

// Source: https://www.guerrilla-games.com/read/decima-engine-advances-in-lighting-and-aa
float getNoHSquared(float radiusTan, float NoL, float NoV, float VoL){
    // radiusCos can be precalculated if radiusTan is a directional light
    float radiusCos = 1.0 / sqrt(1.0 + radiusTan * radiusTan);
    
    // Early out if R falls within the disc
    float RoL = 2.0 * NoL * NoV - VoL;
    if(RoL >= radiusCos) return 1.0;

    float rOverLengthT = radiusCos * radiusTan / sqrt(1.0 - RoL * RoL);
    float NoTr = rOverLengthT * (NoV - RoL * NoL);
    float VoTr = rOverLengthT * (2.0 * NoV * NoV - 1.0 - RoL * VoL);

    // Calculate dot(cross(N, L), V). This could already be calculated and available.
    float triple = sqrt(max(0.0, 1.0 - NoL * NoL - NoV * NoV - VoL * VoL + 2.0 * NoL * NoV * VoL));
    
    // Do one Newton iteration to improve the bent light vector
    float NoBr = rOverLengthT * triple, VoBr = rOverLengthT * (2.0 * triple * NoV);
    float NoLVTr = NoL * radiusCos + NoV + NoTr, VoLVTr = VoL * radiusCos + 1.0 + VoTr;
    float p = NoBr * VoLVTr, q = NoLVTr * VoLVTr, s = VoBr * NoLVTr;
    float xNum = q * (-0.5 * p + 0.25 * VoBr * NoLVTr);
    float xDenom = p * p + s * ((s - 2.0 * p)) + NoLVTr * ((NoL * radiusCos + NoV) * VoLVTr * VoLVTr + 
                   q * (-0.5 * (VoLVTr + VoL * radiusCos) - 0.5));
    float twoX1 = 2.0 * xNum / (xDenom * xDenom + xNum * xNum);
    float sinTheta = twoX1 * xDenom;
    float cosTheta = 1.0 - twoX1 * xNum;
    NoTr = cosTheta * NoTr + sinTheta * NoBr; // use new T to update NoTr
    VoTr = cosTheta * VoTr + sinTheta * VoBr; // use new T to update VoTr
    
    // Calculate (N.H) ^ 2 based on the bent light vector
    float newNoL = NoL * radiusCos + NoTr;
    float newVoL = VoL * radiusCos + VoTr;
    float NoH = NoV + newNoL;
    float HoH = 2.0 * newVoL + 2.0;
    return saturate(NoH * NoH / HoH);
}

// Thanks for LVutner#5199 for his code!
vec3 getSpecBRDF(vec3 V, vec3 L, vec3 N, vec3 albedo, float NL, float metallic, float roughness){
    // Halfway vector
    vec3 H = normalize(L + V);
    
    // Dot products
    float NV = max(0.0, dot(N, V));
    float LH = max(0.0, dot(L, H));
    float LV = dot(L, V);
    
    // Roughness remapping
    float alphaSqrd = squared(roughness * roughness);

    // D
    float NHSqr = getNoHSquared(WORLD_SUN_MOON_SIZE, NL, NV, LV);
    float denominator = NHSqr * (alphaSqrd - 1.0) + 1.0;
    float distribution = alphaSqrd / (PI * denominator * denominator);

    // V
    float visibility = 1.0 / (LH + (1.0 / roughness));
    
    // Calculate and apply fresnel and return final specular
    float cosTheta = exp2(-9.0 * LH);
    if(metallic > 0.9) return getFresnelSchlick(albedo, cosTheta) * (distribution * visibility * NL);
    return vec3(getFresnelSchlick(metallic, cosTheta) * distribution * visibility * NL);
}