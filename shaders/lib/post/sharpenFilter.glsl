// https://www.shadertoy.com/view/lslGRr
vec3 sharpenFilter(sampler2D image, vec3 original, vec2 uv){
    vec2 pixSize = 1.0 / vec2(viewWidth, viewHeight);

    vec3 blur = texture2D(image, uv + pixSize).rgb;
    blur += texture2D(image, uv - pixSize).rgb;
    blur += texture2D(image, uv + vec2(pixSize.x, -pixSize.y)).rgb;
    blur += texture2D(image, uv - vec2(pixSize.x, -pixSize.y)).rgb;
    
    return  (original - blur * 0.25) + original;
}