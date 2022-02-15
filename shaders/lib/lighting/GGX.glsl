vec3 getFresnelSchlick(float cosTheta, vec3 F0){
    // Spherical gaussian fresnel
	return F0 + (1.0 - F0) * exp2(((-5.55473 * cosTheta) - 6.98316) * cosTheta);
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
    float triple = sqrt(saturate(1.0 - NoL * NoL - NoV * NoV - VoL * VoL + 2.0 * NoL * NoV * VoL));
    
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
vec3 getSpecBRDF(vec3 V, vec3 L, vec3 N, vec3 F0, float NL, float roughness){
    // Halfway vector
    vec3 H = normalize(L + V);
    
    // Dot products
    float NV = saturate(dot(N, V));
    float LH = saturate(dot(L, H));
    float LV = dot(L, V);

    // Fresnel
    vec3 fresnel = F0 + (1.0 - F0) * exp2(((-5.55473 * LH) - 6.98316) * LH);
    
    // Roughness remapping
    float alphaSqr = squared(roughness * roughness);
    
    // D
    float NHSqr = getNoHSquared(0.1, NL, NV, LV);
    float denominator = NHSqr * (alphaSqr - 1.0) + 1.0;
    float distribution = alphaSqr / (PI * denominator * denominator);

    // V
    float visibility = 1.0 / (LH + (1.0 / roughness));
    
    // Specular
    return fresnel * (distribution * visibility);
}