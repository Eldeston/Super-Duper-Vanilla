uniform sampler2D normals;
uniform sampler2D specular;

void getPBR(inout matPBR material, mat3 TBN, vec2 st){
    // Get raw textures
	vec4 normalAOH = texture2D(normals, st);
	vec4 SRPSSE = texture2D(specular, st);

    // Decode and extract the materials
    // Extract normals
    vec3 normalMap = normalAOH.xyz * 2.0 - 1.0;
    if(length(normalMap.xy) > 1) normalMap.xy = normalize(normalMap.xy);
    normalMap.z = sqrt(1.0 - dot(normalMap.xy, normalMap.xy));
    // Assign normal
    material.normal_m = normalize(TBN * normalize(clamp(normalMap, -1.0, 1.0)));

    // Assign roughness
    material.roughness_m = pow(1.0 - SRPSSE.r, 2.0);

    // Extract reflectance
    float reflectance = SRPSSE.g * 255.0;
    // Assign metallic
    material.metallic_m = reflectance <= 229 ? reflectance / 229.0 : 0.99;

    // Extact SS
    float PSS = SRPSSE.b * 255.0;
    // Assign SS
    material.ss_m = saturate((PSS - 64.0) / (255.0 - 64.0));

    // Assign emissive
    material.emissive_m = SRPSSE.a * float(SRPSSE.a != 1);

    // Assign ambient
    material.ambient_m = normalAOH.b;
}

void getPBR(inout matPBR material, vec4 albedo, int id){
    float maxCol = maxC(albedo.rgb); float satCol = saturate(rgb2hsv(albedo).y);
    float sumCol = saturate(albedo.r + albedo.g + albedo.b);

    // Default material
    material.metallic_m = 0.0; material.emissive_m = 0.0;
    material.roughness_m = 1.0; material.ss_m = 0.0;
    material.ambient_m = 1.0;

    if(id >= 10001 && id <= 10008){
        material.roughness_m = cubed(maxCol) * 0.5;
        material.ss_m = maxCol;
    }

    if(id == 10009 || id == 10010){
        material.emissive_m = smoothstep(0.5, 1.0, maxCol);
    }

    if(id == 10011){
        material.emissive_m = cubed(albedo.r) * satCol;
        material.metallic_m = material.emissive_m;
    }

    if(id == 10012 || id == 10013){
        material.roughness_m = 0.05;
    }

    if(id == 10015 || id == 10017){
        material.roughness_m = cubed(1.0 - satCol);
        material.metallic_m = satCol * 0.6;
    }

    if(id == 10016){
        material.roughness_m = 1.0 - max2(albedo.gb);
    }

    if(id == 10018){
        material.roughness_m = squared(1.0 - satCol);
        material.metallic_m = smoothstep(0.1, 0.4, satCol);
    }

    if(id == 10019){
        material.roughness_m = squared(1.0 - max2(albedo.gb));
        material.metallic_m = smoothstep(0.2, 0.8, max2(albedo.gb));
    }

    if(id == 10020){
        material.metallic_m = maxCol;
        material.roughness_m = 1.0 - maxCol;
    }

    if(id == 10021){
        material.metallic_m = sumCol;
        material.roughness_m = 1.0 - sumCol;
    }

    if(id == 10030){
        material.emissive_m = 1.0;
    }

    material.roughness_m = max(material.roughness_m, 0.025);
}