// Shadow distortion shape
float getDistortShape(in vec2 shdPos){
    // Should probably swap the shape or calculations
    // to reduce artifacts caused by the distortion

    // return length(shdPos);
    // return sqrt(sqrt(sumOf(squared(squared(shdPos)))));

    vec2 absSquare = abs(shdPos.xy);
    return smoothMax(absSquare.x, absSquare.y, 16.0);
}

// Clip space range [-1, 1]
vec3 getShdClipDistort(in vec3 shdPos, in float distortFactor){
    // This formula maximizes the distortion effectiveness
    distortFactor = distortFactor * 0.9 + 0.1;
    return vec3(shdPos.xy / distortFactor, shdPos.z * 0.2);
}

vec3 getShdClipDistort(in vec3 shdPos){
    float distortFactor = getDistortShape(shdPos.xy);
    return getShdClipDistort(shdPos, distortFactor);
}

// Screen space range [0, 1]
vec3 getShdDistort(in vec3 shdPos, in float distortFactor){
    // This formula maximizes the distortion effectiveness
    distortFactor = distortFactor * 1.8 + 0.2;
    return vec3(shdPos.xy / distortFactor, shdPos.z * 0.1) + 0.5;
}

vec3 getShdDistort(in vec3 shdPos){
    float distortFactor = getDistortShape(shdPos.xy);
    return getShdDistort(shdPos, distortFactor);
}