// 1 pass blur with LOD
vec3 blur1(sampler2D image, vec2 st, vec2 resolution, int samples, float size){
    vec2 pixSize = (size * 4.0) / resolution;
    int halfSample = samples / 2;
    vec3 frag = texture2D(image, st, 0.025 * size).rgb;
    if(samples > 1){
        for(int i = 1 - halfSample; i < samples - halfSample; i++){
            vec2 offSet = float(i) / float(samples) * pixSize;
            frag += texture2D(image, st + offSet, 0.05 * size).rgb;
        }
    }
    return frag / samples;
}

/* // 2 pass blur with LOD
vec4 blur2(sampler2D image, vec2 st, vec2 resolution, int samples, float size){
    vec2 pixSize = (size * 4.0) / resolution;
    int halfSample = samples / 2;
    vec4 frag = texture2D(image, st);
    if(samples > 1){
        for(int i = 1 - halfSample; i < samples - halfSample; i++){
            float offSet = float(i) / float(samples);
            frag += texture2D(image, st + vec2(offSet, 0.0) * pixSize, 0.01 * size);
            frag += texture2D(image, st + vec2(0.0, offSet) * pixSize, 0.01 * size);
        }
    }
    return frag / float(samples * 2 - 1);
}
*/

vec3 blur2(sampler2D image, vec2 st, vec2 resolution, int samples, float size){
    vec2 pixSize = size / resolution;
    vec3 col = texture2D(image, st, 0.025 * size).rgb;
    if(samples > 1){
        for(int x = 0; x < samples; x++){
            float piX = (float(x) * PI2) / float(samples);
            col += texture2D(image, st + vec2(sin(piX), cos(piX)) * pixSize, 0.05 * size).rgb;
        }
    }
    return col / (samples + 1);
}