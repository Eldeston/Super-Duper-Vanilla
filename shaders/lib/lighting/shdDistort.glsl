vec3 getShdClipDistort(vec3 shdPos){
    // Clip space range [-1, 1]
    // return vec3(shdPos.xy / (length(shdPos.xy) + 0.1), shdPos.z * 0.2);
    float distortFactor = length(shdPos.xy) * 0.9 + 0.1;
    return vec3(shdPos.xy / distortFactor, shdPos.z * 0.2);
}

vec3 getShdDistort(vec3 shdPos){
    // Screen space range [0, 1]
    // return vec3(shdPos.xy / (length(shdPos.xy) * 2.0 + 0.2), shdPos.z * 0.1) + 0.5;
    float distortFactor = length(shdPos.xy) * 1.8 + 0.2;
    return vec3(shdPos.xy / distortFactor, shdPos.z * 0.1) + 0.5;
}