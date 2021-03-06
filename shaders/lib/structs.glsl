// Material PBR struct
struct matPBR{
    // Albedo texture
    vec4 albedo_t;
    // Normal map
    vec3 normal_m;
    // Light map
    vec2 light_m;
    // Metalic map
    float metallic_m;
    // Emissive map
	float emissive_m;
    // Roughness map
    float roughness_m;
    // Ambient map
    float ambient_m;
    // Subsurface scattering
    float ss_m;
};

// Position struct
struct positionVectors{
    // Screen pos
    vec3 screenPos;
    // Clip pos
    vec3 clipPos;
    // View position
    vec3 viewPos;
    // Player pos from the eye
    vec3 eyePlayerPos;
    // Player pos from the foot
    vec3 feetPlayerPos;
    // World/scene position
    vec3 worldPos;
    // Light position
    vec3 lightPos;

    // Shadow position
    vec4 shdPos;
};