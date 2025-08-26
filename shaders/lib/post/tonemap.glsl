const float oneMinusShoulder = 1.0 - SHOULDER_STRENGTH;

const float shoulderFactor = oneMinusShoulder * 3.0;
const float shoulderWhitePointFactor = oneMinusShoulder / (WHITE_POINT * WHITE_POINT);

// Luminance function
float getLuminance(in vec3 col){
    return dot(col, vec3(0.2126, 0.7152, 0.0722));
}

// Saturation function
vec3 saturation(in vec3 col, in float a){
    float luma = getLuminance(col);
    return (col - luma) * a + luma;
}

// Contrast function
vec3 contrast(in vec3 col, in float a){
    return (col - 0.5) * a + 0.5;
}

// Modified Reinhard extended luminance tonemapping
vec3 modifiedReinhardExtended(in vec3 color){
    float sumCol = sumOf(color);
    return color * ((3.0 + sumCol * shoulderWhitePointFactor) / (shoulderFactor + sumCol));
}

/*
vec3 modifiedReinhardExtended(in vec3 color){
    color *= EXPOSURE;
    float sumCol = sumOf(color);
    float rainHardFactor = (3.0 + sumCol * shoulderWhitePointFactor) / (shoulderFactor + sumCol);
    vec3 tonemapped = color * rainHardFactor;

    // Color tinting, exposure, and tonemapping
    const float coefficient = exp2(EXPOSURE) - 1.0;
    vec3 exposureFactor = (coefficient * tonemapped) / (1.0 + (coefficient - 1.0) * tonemapped);

    return tonemapped;
}

float coefficient = EXPOSURE * 0.00392156863;
(coefficient * color + color) / (coefficient * color + 1.0)
(coefficient * color) / (1.0 + (coefficient - 1.0) * color)
*/

// Modified Reinhard Jodie extended tonemapping
// Might eventually become an option...maybe
vec3 modifiedReinhardJodieExtended(in vec3 color){
    float sumCol = sumOf(color);

    vec3 reinhardColorFactor = color * ((1.0 + color * shoulderWhitePointFactor) / (oneMinusShoulder + color));
    vec3 reinhardLumaFactor = color * ((3.0 + sumCol * shoulderWhitePointFactor) / (shoulderFactor + sumCol));

    return (reinhardColorFactor - reinhardLumaFactor) * reinhardColorFactor + reinhardLumaFactor;
}