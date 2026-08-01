// Source: https://www.guerrilla-games.com/read/decima-engine-advances-in-lighting-and-aa
float getNoHSquared(in float NoL, in float NoV, in float VoL){
    // radiusTan == WORLD_SUN_MOON_SIZE
    // radiusCos can be precalculated if radiusTan is a directional light
    const float radiusCos = inversesqrt(1.0 + WORLD_SUN_MOON_SIZE * WORLD_SUN_MOON_SIZE);

    // Early out if R falls within the disc
    float NoLNoV = 2.0 * NoL * NoV;
    float RoL = NoLNoV - VoL;
    if(RoL >= radiusCos) return 1.0;

    const float radiusCosScale = radiusCos * WORLD_SUN_MOON_SIZE;

    float NoVSqrd = NoV * NoV;

    float rOverLengthT = inversesqrt(1.0 - RoL * RoL) * radiusCosScale;
    float NoTr = rOverLengthT * (NoV - RoL * NoL);
    float VoTr = rOverLengthT * (2.0 * NoVSqrd - 1.0 - RoL * VoL);

    // Calculate dot(cross(N, vec3(shadowModelView[0].z, shadowModelView[1].z, shadowModelView[2].z)), V). This could already be calculated and available.
    float tripleDelta = 1.0 - NoL * NoL - NoVSqrd - VoL * VoL + NoLNoV * VoL;
    float tripleAlpha = tripleDelta > 0 ? rOverLengthT * sqrt(tripleDelta) : 0.0;

    // Do one Newton iteration to improve the bent light vector
    float NoBr = tripleAlpha;
    float VoBr = 2.0 * tripleAlpha * NoV;
    float NoLVTr = NoL * radiusCos + NoV + NoTr;
    float VoLVTr = VoL * radiusCos + 1.0 + VoTr;

    float p = NoBr * VoLVTr;
    float q = NoLVTr * VoLVTr;
    float s = VoBr * NoLVTr;

    float xNum = q * (0.25 * s - 0.5 * p);
    float xDenom = p * p + s * (s - 2.0 * p) + NoLVTr * ((NoL * radiusCos + NoV) * VoLVTr * VoLVTr -
        q * (0.5 * (VoLVTr + VoL * radiusCos) + 0.5));

    float twoX1 = 2.0 * xNum / (xDenom * xDenom + xNum * xNum);
    float sinTheta = twoX1 * xDenom;
    float cosTheta = 1.0 - twoX1 * xNum;

    // Use new T to update NoTr
    NoTr = cosTheta * NoTr + sinTheta * NoBr;
    // Use new T to update VoTr
    VoTr = cosTheta * VoTr + sinTheta * VoBr;

    // Calculate (N.H) ^ 2 based on the bent light vector
    float newNoL = NoL * radiusCos + NoTr;
    float newVoL = VoL * radiusCos + VoTr;

    float NoH = NoV + newNoL;
    float HoH = 2.0 * newVoL + 2.0;

    return min(1.0, NoH * NoH / HoH);
}

// Modified fast specular BRDF
// Thanks for LVutner#5199 for sharing his code!
vec3 getSpecularBRDF(in vec3 V, in vec3 N, in vec3 albedo, in float NL, in float NV, in float metallic, in float smoothness){
    // Halfway vector
    vec3 H = fastNormalize(vec3(shadowModelView[0].z, shadowModelView[1].z, shadowModelView[2].z) + V);
    // Light dot halfway vector
    float LH = dot(vec3(shadowModelView[0].z, shadowModelView[1].z, shadowModelView[2].z), H);

    // Roughness remapping
    float roughness = 1.0 - smoothness;
    float alphaSqrd = squared(roughness * roughness);

    // Visibility
    float visibility = LH + (1.0 / roughness);

    // Smoothness needed to be multiplied in the rest of the calculation for compensating reflection over specular
    float specularMult = smoothness + 1.0;
    float specIntensity = sunMoonIntensitySqrd * specularMult;

    // Distribution
    float NHSqr = getNoHSquared(NL, NV, dot(V, vec3(shadowModelView[0].z, shadowModelView[1].z, shadowModelView[2].z)));
    float denominator = squared(NHSqr * (alphaSqrd - 1.0) + 1.0);
    float distribution = (specularMult * alphaSqrd * NL) / (denominator * visibility * PI);

    // Rain occlusion
    #ifndef FORCE_DISABLE_WEATHER
        distribution *= 1.0 - rainStrength;
    #endif

    // Calculate and apply fresnel and return final specular
    float cosTheta = exp2(-9.28 * LH);
	float oneMinusCosTheta = 1.0 - cosTheta;

    if(metallic <= 0.9){
        float basicFresnel = cosTheta + metallic * oneMinusCosTheta;
        return vec3(min(specIntensity, basicFresnel * distribution));
    }

    vec3 metallicFresnel = cosTheta + albedo * oneMinusCosTheta;
    return min(vec3(specIntensity * PI), metallicFresnel * distribution);
}