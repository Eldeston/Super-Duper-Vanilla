#if WORLD_ID == 0 && !defined FORCE_DISABLE_WEATHER
    #ifndef THUNDER_STRENGTH_DECLARED
        #define THUNDER_STRENGTH_DECLARED
        uniform float thunderStrength;
    #endif
#endif

// Source: https://www.guerrilla-games.com/read/decima-engine-advances-in-lighting-and-aa
float getNoHSquared(in float NoL, in float NoV, in float VoL, in vec3 V, in vec3 N){
    // Light basis vectors in view space from shadowModelView
    vec3 lightDir  = vec3(shadowModelView[0].z, shadowModelView[1].z, shadowModelView[2].z);
    vec3 lightTanX = vec3(shadowModelView[0].x, shadowModelView[1].x, shadowModelView[2].x);
    vec3 lightTanY = vec3(shadowModelView[0].y, shadowModelView[1].y, shadowModelView[2].y);

    // Reflected view ray: R = reflect(-V, N) = 2.0 * NoV * N - V
    vec3 R = (2.0 * NoV) * N - V;

    float RoL = dot(R, lightDir);
    float Rx  = dot(R, lightTanX);
    float Ry  = dot(R, lightTanY);

    float effRadiusTan = WORLD_SUN_MOON_SIZE;
    float effRadiusCos = inversesqrt(1.0 + effRadiusTan * effRadiusTan);

    if(RoL > 0.0){
        vec2 coord = vec2(Rx, Ry) / RoL;
        
        // Squircle distance function matching getSunMoonDist in skyRender.glsl
        float r = SUN_MOON_ROUNDNESS * WORLD_SUN_MOON_SIZE;
        vec2 q = abs(coord) - vec2(WORLD_SUN_MOON_SIZE - r);
        float dist = min(max(q.x, q.y), 0.0) + length(max(q, vec2(0.0))) - r + WORLD_SUN_MOON_SIZE;

        // Early out if reflected ray R falls within the celestial body (square, squircle, or disc)
        if(dist <= WORLD_SUN_MOON_SIZE) return 1.0;

        // Effective angular radius at this angle for Decima area light falloff
        effRadiusTan = length(coord) * (WORLD_SUN_MOON_SIZE / max(dist, 0.0001));
        effRadiusCos = inversesqrt(1.0 + effRadiusTan * effRadiusTan);
    } else {
        if(RoL >= effRadiusCos) return 1.0;
    }

    float radiusCosScale = effRadiusCos * effRadiusTan;

    float NoVSqrd = NoV * NoV;

    float rOverLengthT = inversesqrt(max(0.0001, 1.0 - RoL * RoL)) * radiusCosScale;
    float NoTr = rOverLengthT * (NoV - RoL * NoL);
    float VoTr = rOverLengthT * (2.0 * NoVSqrd - 1.0 - RoL * VoL);

    // Calculate dot(cross(N, lightDir), V)
    float tripleDelta = 1.0 - NoL * NoL - NoVSqrd - VoL * VoL + (2.0 * NoL * NoV) * VoL;
    float tripleAlpha = tripleDelta > 0.0 ? rOverLengthT * sqrt(tripleDelta) : 0.0;

    // Do one Newton iteration to improve the bent light vector
    float NoBr = tripleAlpha;
    float VoBr = 2.0 * tripleAlpha * NoV;
    float NoLVTr = NoL * effRadiusCos + NoV + NoTr;
    float VoLVTr = VoL * effRadiusCos + 1.0 + VoTr;

    float p = NoBr * VoLVTr;
    float q = NoLVTr * VoLVTr;
    float s = VoBr * NoLVTr;

    float xNum = q * (0.25 * s - 0.5 * p);
    float xDenom = p * p + s * (s - 2.0 * p) + NoLVTr * ((NoL * effRadiusCos + NoV) * VoLVTr * VoLVTr -
        q * (0.5 * (VoLVTr + VoL * effRadiusCos) + 0.5));

    float twoX1 = 2.0 * xNum / (xDenom * xDenom + xNum * xNum);
    float sinTheta = twoX1 * xDenom;
    float cosTheta = 1.0 - twoX1 * xNum;

    // Use new T to update NoTr
    NoTr = cosTheta * NoTr + sinTheta * NoBr;
    // Use new T to update VoTr
    VoTr = cosTheta * VoTr + sinTheta * VoBr;

    // Calculate (N.H) ^ 2 based on the bent light vector
    float newNoL = NoL * effRadiusCos + NoTr;
    float newVoL = VoL * effRadiusCos + VoTr;

    float NoH = NoV + newNoL;
    float HoH = 2.0 * newVoL + 2.0;

    return min(1.0, NoH * NoH / HoH);
}

// Modified fast specular BRDF
// Thanks for LVutner#5199 for sharing his code!
vec3 getSpecularBRDF(in vec3 V, in vec3 N, in vec3 albedo, in float NL, in float NV, in float metallic, in float smoothness){
    // Early exit if light faces away, smoothness is negligible, or sun/moon is off
    if(NL <= 0.0 || smoothness <= 0.001 || sunMoonIntensitySqrd <= 0.0001) return vec3(0.0);

    vec3 lightDir = vec3(shadowModelView[0].z, shadowModelView[1].z, shadowModelView[2].z);

    // Halfway vector
    vec3 H = fastNormalize(lightDir + V);
    // Light dot halfway vector
    float LH = dot(lightDir, H);

    // Roughness remapping
    float roughness = 1.0 - smoothness;
    float alphaSqrd = squared(roughness * roughness);

    // Visibility
    float visibility = LH + (1.0 / roughness);

    // Smoothness needed to be multiplied in the rest of the calculation for compensating reflection over specular
    float specularMult = smoothness + 1.0;
    float specIntensity = sunMoonIntensitySqrd * specularMult;

    // Distribution
    float NHSqr = getNoHSquared(NL, NV, dot(V, lightDir), V, N);
    float denominator = squared(NHSqr * (alphaSqrd - 1.0) + 1.0);
    float distribution = (specularMult * alphaSqrd * NL) / (denominator * visibility * PI);

    // Rain occlusion
    #ifndef FORCE_DISABLE_WEATHER
        #if WORLD_ID == 0
            float effectiveWeatherFade = clamp(max(weatherFade, thunderStrength), 0.0, 1.0);
        #else
            float effectiveWeatherFade = weatherFade;
        #endif
        distribution *= 1.0 - effectiveWeatherFade;
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