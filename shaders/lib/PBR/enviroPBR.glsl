// Environment PBR calculation
void enviroPBR(inout dataPBR material){
    if(TBN[2].y < 0) return;

    float skyLightDelta = lmCoord.y - 0.8;

    if(skyLightDelta < 0) return;

    float rainMatFact = (1.0 - material.porosity) * skyLightDelta * isPrecipitationRain * TBN[2].y * 5.0;

    rainMatFact *= saturate(sumOf(textureLod(noisetex, vertexWorldPos.xz * 0.001953125, 0).xy) - 0.5);

    material.normal = mix(material.normal, TBN[2], rainMatFact);
    material.metallic = max(0.02 * rainMatFact, material.metallic);
    material.smoothness = mix(material.smoothness, 0.96, rainMatFact);
    material.albedo.rgb *= 1.0 - rainMatFact * 0.5;
}