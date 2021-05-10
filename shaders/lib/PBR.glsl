uniform sampler2D normals;
uniform sampler2D specular;

void getPBR(inout matPBR material, mat3 TBN, vec2 st){
    // Get raw textures
	vec4 normalAOH = texture2D(normals, st);
	vec4 SRPSSE = texture2D(specular, st);

    // Encode and extract the materials
    vec3 normalMap = normalAOH.xyz * 2.0 - 1.0;
    normalMap.z = saturate(sqrt(1.0 - dot(normalMap.xy, normalMap.xy)));
    // Assign normal
    material.normal_m = normalize(TBN * normalMap);

    // Assign ambient
    material.ambient_m = normalAOH.b;

    // Assign roughness
    material.roughness_m = pow(1.0 - SRPSSE.r, 2.0);

    // Extract reflectance
    float reflectance = SRPSSE.g * 255.0;
    // Assign metallic
    material.metallic_m = min(1.0, reflectance / 229.0);

    // Extact SS
    float PSS = SRPSSE.b * 255.0;
    // Assign SS
    material.ss_m = saturate((PSS - 64.0) / (255.0 - 64.0));

    // Assign emissive
    material.emissive_m = min(1.0, SRPSSE.a / 254.0);
}