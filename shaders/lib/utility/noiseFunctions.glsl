// https://blog.demofox.org/2022/01/01/interleaved-gradient-noise-a-different-kind-of-low-discrepancy-sequence/
float IGN(in vec2 pixel, in int frame){
    float f = float(frame & 63);
    vec2 p = pixel + 5.588238 * f;

    return mod(52.9829189 * mod(0.06711056 * p.x + 0.00583715 * p.y, 1), 1);
}