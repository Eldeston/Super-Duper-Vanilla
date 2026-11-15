// https://blog.demofox.org/2022/01/01/interleaved-gradient-noise-a-different-kind-of-low-discrepancy-sequence/
float IGN(in vec2 pixel, in int frame){
    float f = float(frame & 63);
    vec2 p = pixel + 5.588238 * f;

    return fract(52.9829189 * fract(0.06711056 * p.x + 0.00583715 * p.y));
}

float IGN(in vec2 pixel){
    return fract(52.9829189 * fract(0.06711056 * pixel.x + 0.00583715 * pixel.y));
}

// https://blog.demofox.org/2022/02/01/two-low-discrepancy-grids-plus-shaped-sampling-ldg-and-r2-ldg/
const float g = 1.32471795724474602596;
const float g2 = g * g;

float R2(in vec2 pixel, in int frame){
    float f = float(frame & 63);
    vec2 p = pixel + 5.588238 * f;

    return fract(p.x / g + p.y / g2);
}

float R2(in vec2 pixel){
    return fract(pixel.x / g + pixel.y / g2);
}