uniform sampler2D normals;
uniform sampler2D specular;

void getPBR(inout matPBR material, mat3 TBN, vec2 st){
    // Get raw textures
	vec4 normalAOH = texture2D(normals, st);
	vec4 SRPSSE = texture2D(specular, st);

    // Decode and extract the materials
    // Extract normals
    vec3 normalMap = normalAOH.xyz * 2.0 - 1.0;
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

void getPBR(inout matPBR material, int id){
    vec3 hsv = saturate(rgb2hsv(material.albedo_t));
    float maxCol = maxC(material.albedo_t.rgb);
    float sumCol = saturate(material.albedo_t.r + material.albedo_t.g + material.albedo_t.b);

    // Default material
    material.metallic_m = 0.0; material.emissive_m = 0.0;
    material.roughness_m = 1.0; material.ss_m = 0.0;
    material.ambient_m = 1.0;

    // Foliage and corals
    if(id >= 10000 && id <= 10008) material.ss_m = 0.8;

    // Emissives
    if(id == 10009 || id == 10010) material.emissive_m = smoothstep(0.5, 1.0, maxCol);

    // Redstone
    if(id == 10011){
        material.emissive_m = cubed(material.albedo_t.r) * hsv.y;
        material.roughness_m = (1.0 - material.emissive_m);
        material.metallic_m = material.emissive_m;
    }

    // Glass
    if(id == 10012 || id == 10013) material.roughness_m = 0.056;

    // Gem ores and blocks
    if(id == 10015 || id == 10017){
        material.roughness_m = cubed(1.0 - hsv.y);
        material.metallic_m = hsv.y * 0.6;
    }

    // Netherack gem ores
    if(id == 10016) material.roughness_m = material.albedo_t.r;

    // Metal ores
    if(id == 10018){
        material.roughness_m = squared(1.0 - hsv.y);
        material.metallic_m = smoothstep(0.1, 0.4, hsv.y);
    }

    // Netherack metal ores
    if(id == 10019){
        material.metallic_m = smoothstep(0.5, 0.75, max2(material.albedo_t.rg));;
        material.roughness_m = smoothstep(0.75, 0.5, max2(material.albedo_t.rg));;
    }

    // Metal blocks
    if(id == 10020){
        material.metallic_m = maxCol;
        material.roughness_m = 1.0 - maxCol;
    }

    // Netherite block
    if(id == 10021){
        material.metallic_m = sumCol;
        material.roughness_m = 1.0 - sumCol;
    }

    // Polished blocks
    if(id == 10022) material.roughness_m = 1.0 - sumCol;

    // End portal
    if(id == 10030) material.emissive_m = 1.0;

    material.roughness_m = max(material.roughness_m, 0.028);
}

void enviroPBR(inout matPBR material, in vec3 rawNorm){
    float rainMatFact = saturate(rainStrength * 0.972 * sqrt(material.normal_m.y) * cubed(material.light_m.y));
    material.normal_m = mix(material.normal_m, rawNorm, rainMatFact);
    material.roughness_m = material.roughness_m * (1.0 - rainMatFact);
}