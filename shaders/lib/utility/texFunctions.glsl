vec4 texPix2DBilinear(sampler2D image, vec2 st, vec2 texSize){
    vec2 pixSize = 1.0 / texSize;

    vec4 downLeft = texture2D(image, st);
    vec4 downRight = texture2D(image, st + vec2(pixSize.x, 0));

    vec4 upRight = texture2D(image, st + vec2(0, pixSize.y));
    vec4 upLeft = texture2D(image, st + vec2(pixSize.x , pixSize.y));

    float a = fract(st.x * texSize.x);
    float b = fract(st.y * texSize.y);

    vec4 horizontal0 = mix(downLeft, downRight, a);
    vec4 horizontal1 = mix(upRight, upLeft, a);
    return mix(horizontal0, horizontal1, b);
}

vec4 texPix2DCubic(sampler2D image, vec2 st, vec2 texSize){
    vec2 pixSize = 1.0 / texSize;

    vec4 downLeft = texture2D(image, st);
    vec4 downRight = texture2D(image, st + vec2(pixSize.x, 0));

    vec4 upRight = texture2D(image, st + vec2(0, pixSize.y));
    vec4 upLeft = texture2D(image, st + vec2(pixSize.x , pixSize.y));

    float a = smoothen(fract(st.x * texSize.x));
    float b = smoothen(fract(st.y * texSize.y));

    vec4 horizontal0 = mix(downLeft, downRight, a);
    vec4 horizontal1 = mix(upRight, upLeft, a);
    return mix(horizontal0, horizontal1, b);
}

vec4 texture2DBox(sampler2D image, vec2 texCoords, vec2 texSize){
    vec2 pixSize = 1.0 / texSize;
	vec4 sample = texture2D(image, texCoords - pixSize) + texture2D(image, texCoords + pixSize) +
    texture2D(image, texCoords - vec2(-pixSize.x, pixSize.y)) + texture2D(image, texCoords + vec2(-pixSize.x, pixSize.y));
	return sample * 0.25;
	}