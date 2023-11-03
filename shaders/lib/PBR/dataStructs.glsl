// Material PBR data struct
struct dataPBR{
    // Albedo texture
    vec4 albedo;
    // Normal map
    vec3 normal;
    // Metalic map
    float metallic;
    // Emissive map
	float emissive;
    // Smoothness map
    float smoothness;
    // Ambient map
    float ambient;
    // Porosity
    float porosity;
    // Subsurface scattering
    float ss;
    // POM self shadows
    float parallaxShd;
};

/*
// Texture coordinate data struct
struct dataTexCoord{
    // Derivatives
    vec2 texDFdx;
    vec2 texDFdy;
    // Main texcoord
    vec2 texCoord;
};
*/