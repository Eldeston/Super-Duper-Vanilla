// 0.06136 0.24477 0.38774 0.24477 0.06136

/*
// 1 pass blur with LOD (old)
vec3 blur1x(sampler2D image, vec2 st, vec2 resolution, int samples, float size){
    float pixSize = max2(size / resolution) * 2.0;
    int halfSample = samples / 2;
    vec3 frag = texture2D(image, st, 0.0375 * size).rgb;
    if(samples > 1){
        for(int i = 1 - halfSample; i < samples - halfSample; i++){
            float offSet = float(i) / float(samples) * pixSize;
            frag += texture2D(image, st + vec2(offSet, 0.0), 0.05 * size).rgb;
        }
    }
    return frag / samples;
}
*/

// 1 pass blur with LOD
vec3 blur1x(sampler2D image, vec2 st, vec2 resolution, float size){
    float maxRes = max2(resolution);
    vec3 frag = texture2D(image, st, 0.25 * size).rgb * 0.38774;
    frag += texture2D(image, st + vec2((size * 2.0) / maxRes, 0.0), 0.25 * size).rgb * 0.06136;
    frag += texture2D(image, st + vec2(size / maxRes, 0.0), 0.25 * size).rgb * 0.24477;
    frag += texture2D(image, st - vec2(size / maxRes, 0.0), 0.25 * size).rgb * 0.24477;
    frag += texture2D(image, st - vec2((size * 2.0) / maxRes, 0.0), 0.25 * size).rgb * 0.06136;
    return frag;
}

// 1 pass blur with LOD
vec3 blur1y(sampler2D image, vec2 st, vec2 resolution, float size){
    float maxRes = max2(resolution) * 2.0;
    vec3 frag = texture2D(image, st, 0.25 * size).rgb * 0.38774;
    frag += texture2D(image, st + vec2(0.0, (size * 2.0) / maxRes), 0.125 * size).rgb * 0.06136;
    frag += texture2D(image, st + vec2(0.0, size / maxRes), 0.125 * size).rgb * 0.24477;
    frag += texture2D(image, st - vec2(0.0, size / maxRes), 0.125 * size).rgb * 0.24477;
    frag += texture2D(image, st - vec2(0.0, (size * 2.0) / maxRes), 0.125 * size).rgb * 0.06136;
    return frag;
}

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