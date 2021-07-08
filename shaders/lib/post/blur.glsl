// Radial blur with LOD
vec3 blur2(sampler2D image, vec2 st, vec2 resolution, int samples, float size){
    vec2 pixSize = size / resolution;
    vec3 col = texture2D(image, st, 0.25 * size).rgb;
    if(samples > 1){
        for(int x = 0; x < samples; x++){
            float piX = (float(x) * PI2) / float(samples);
            col += texture2D(image, st + vec2(sin(piX), cos(piX)) * pixSize, 0.125 * size).rgb;
        }
    }
    return col / (samples + 1);
}