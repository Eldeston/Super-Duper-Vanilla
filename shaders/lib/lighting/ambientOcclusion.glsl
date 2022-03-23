vec3 ambientOcclusion(vec3 viewPos, vec3 normal, vec3 dither){
    float occlusion = 0.0;

    for(int i = 0; i < 4; i++){
        vec3 sampleDir = normal + fract(dither + i * 0.25);

        vec3 samplePos = viewPos + sampleDir * 0.5;
        float sampleDepth = texture2D(depthtex0, toScreen(samplePos).xy).x;

        occlusion += sampleDepth > samplePos.z + 0.025 ? smootherstep(0.5 / abs(viewPos.z - sampleDepth)) : 0.0;
    }

    return saturate(cubed(1.0 - (occlusion * 0.25)));
}