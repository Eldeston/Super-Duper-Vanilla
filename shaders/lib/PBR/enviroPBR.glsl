// Environment PBR calculation
void enviroPBR(inout dataPBR material, in vec3 normal){
    if(normal.y < 0.005) return;

    float skyLightDelta = lmCoord.y - 0.8;

    if(skyLightDelta < 0) return;

    float rainMatFact = (1.0 - material.porosity) * skyLightDelta * isPrecipitationRain * normal.y * 5.0;

    rainMatFact *= saturate(sumOf(textureLod(noisetex, vertexWorldPos.xz * 0.001953125, 0).xy) - 0.5);

    material.normal = mix(material.normal, normal, rainMatFact);
    material.metallic = max(0.02 * rainMatFact, material.metallic);
    material.smoothness = mix(material.smoothness, 0.96, rainMatFact);
    material.albedo.rgb *= 1.0 - rainMatFact * 0.5;
}