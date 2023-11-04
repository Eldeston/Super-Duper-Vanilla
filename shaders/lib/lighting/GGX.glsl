vec3 getFresnelSchlick(in vec3 F0, in float cosTheta){
	return F0 + (1.0 - F0) * cosTheta;
}

float getFresnelSchlick(in float F0, in float cosTheta){
	return F0 + (1.0 - F0) * cosTheta;
}

// Source: https://www.guerrilla-games.com/read/decima-engine-advances-in-lighting-and-aa
float getNoHSquared(in float NoL, in float NoV, in float VoL){
    // radiusTan == WORLD_SUN_MOON_SIZE
    // radiusCos can be precalculated if radiusTan is a directional light
    const float radiusCos = inversesqrt(1.0 + WORLD_SUN_MOON_SIZE * WORLD_SUN_MOON_SIZE);

    // Early out if R falls within the disc
    float RoL = 2.0 * NoL * NoV - VoL;
    if(RoL >= radiusCos) return 1.0;

    float rOverLengthT = radiusCos * WORLD_SUN_MOON_SIZE * inversesqrt(1.0 - RoL * RoL);
    float NoTr = rOverLengthT * (NoV - RoL * NoL);
    float VoTr = rOverLengthT * (2.0 * NoV * NoV - 1.0 - RoL * VoL);

    // Calculate dot(cross(N, vec3(shadowModelView[0].z, shadowModelView[1].z, shadowModelView[2].z)), V). This could already be calculated and available.
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
    return min(1.0, NoH * NoH / HoH);
}

// Modified fast specular BRDF
// Thanks for LVutner#5199 for sharing his code!
vec3 getSpecularBRDF(in vec3 V, in vec3 N, in vec3 albedo, in float NL, in float metallic, in float smoothness){
    // Halfway vector
    vec3 H = fastNormalize(vec3(shadowModelView[0].z, shadowModelView[1].z, shadowModelView[2].z) + V);
    // Light dot halfway vector
    float LH = dot(vec3(shadowModelView[0].z, shadowModelView[1].z, shadowModelView[2].z), H);

    // Roughness remapping
    float roughness = 1.0 - smoothness;
    float alpha = roughness * roughness;
    float alphaSqrd = alpha * alpha;

    // Visibility
    float visibility = LH + (1.0 / roughness);

    // Distribution
    // Roughness needed to be divided in the rest of the calculation for compensating reflection over specular
    float NHSqr = getNoHSquared(NL, dot(N, V), dot(V, vec3(shadowModelView[0].z, shadowModelView[1].z, shadowModelView[2].z)));
    float denominator = squared(NHSqr * (alphaSqrd - 1.0) + 1.0);
    float distribution = (alpha * roughness * NL) / (denominator * visibility * PI);

    // Rain occlusion
    #ifndef FORCE_DISABLE_WEATHER
        distribution *= 1.0 - rainStrength;
    #endif

    // Calculate and apply fresnel and return final specular
    float cosTheta = exp2(-9.28 * LH);
	float oneMinusCosTheta = 1.0 - cosTheta;

	float basicFresnel = cosTheta + metallic * oneMinusCosTheta;
    if(metallic <= 0.9) return vec3(min(sunMoonIntensitySqrd, basicFresnel * distribution * roughness) / (1.0 - basicFresnel * smoothness));

    vec3 metallicFresnel = cosTheta + albedo * oneMinusCosTheta;
    return min(vec3(sunMoonIntensitySqrd / roughness), metallicFresnel * distribution);
}