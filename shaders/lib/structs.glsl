// Material PBR struct
struct matPBR{
    // Albedo texture
    vec4 albedo;
    // Normal map
    vec3 normal;
    // Light map
    vec2 light;
    // Metalic map
    float metallic;
    // Emissive map
	float emissive;
    // Smoothness map
    float smoothness;
    // Ambient map
    float ambient;
    // Subsurface scattering
    float ss;
};

// Position struct
struct positionVectors{
    // Screen pos
    vec3 screenPos;
    // View position
    vec3 viewPos;
    // Player pos from the eye
    vec3 eyePlayerPos;
    // Player pos from the foot
    vec3 feetPlayerPos;
    // World/scene position
    vec3 worldPos;
    // Shadow position
    vec3 shdPos;
};