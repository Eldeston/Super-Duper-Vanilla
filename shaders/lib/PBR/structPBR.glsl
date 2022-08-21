// Material PBR struct
struct structPBR{
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