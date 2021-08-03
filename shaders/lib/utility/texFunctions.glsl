// Filter by iq
vec4 tex2DBicubic(sampler2D image, vec2 st, vec2 texRes){
    vec2 uv = st * texRes + 0.5;
    vec2 iuv = floor(uv); vec2 fuv = fract(uv);
    uv = iuv + fuv * fuv * fuv * (fuv * (fuv * 6.0 - 15.0) + 10.0);
    uv = (uv - 0.5) / texRes;
    return texture2D(image, uv);
}

vec4 texPix2DBilinear(sampler2D image, vec2 st, vec2 texRes){
    vec2 pixSize = 1.0 / texRes;

    vec4 downLeft = texture2D(image, st);
    vec4 downRight = texture2D(image, st + vec2(pixSize.x, 0));

    vec4 upRight = texture2D(image, st + vec2(0, pixSize.y));
    vec4 upLeft = texture2D(image, st + vec2(pixSize.x , pixSize.y));

    float a = fract(st.x * texRes.x);
    float b = fract(st.y * texRes.y);

    vec4 horizontal0 = mix(downLeft, downRight, a);
    vec4 horizontal1 = mix(upRight, upLeft, a);
    return mix(horizontal0, horizontal1, b);
}

vec4 texPix2DBicubic(sampler2D image, vec2 st, vec2 texRes){
    vec2 pixSize = 1.0 / texRes;

    vec4 downLeft = texture2D(image, st);
    vec4 downRight = texture2D(image, st + vec2(pixSize.x, 0));

    vec4 upRight = texture2D(image, st + vec2(0, pixSize.y));
    vec4 upLeft = texture2D(image, st + vec2(pixSize.x , pixSize.y));

    float a = smootherstep(fract(st.x * texRes.x));
    float b = smootherstep(fract(st.y * texRes.y));

    vec4 horizontal0 = mix(downLeft, downRight, a);
    vec4 horizontal1 = mix(upRight, upLeft, a);
    return mix(horizontal0, horizontal1, b);
}