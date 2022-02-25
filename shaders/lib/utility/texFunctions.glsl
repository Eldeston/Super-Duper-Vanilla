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

vec4 cubic(float v){
    vec4 n = vec4(1, 2, 3, 4) - v;
    vec4 s = n * n * n;
    float x = s.x;
    float y = s.y - 4.0 * s.x;
    float z = s.z - 4.0 * s.y + 6.0 * s.x;
    float w = 6.0 - x - y - z;
    return vec4(x, y, z, w) / 6.0;
}

vec4 texture2DBicubic(sampler2D image, vec2 texCoords, vec2 texSize){
    vec2 invTexSize = 1.0 / texSize;

    texCoords = texCoords * texSize - 0.5;

    vec2 fxy = fract(texCoords);
    texCoords -= fxy;
 
    vec4 xcubic = cubic(fxy.x);
    vec4 ycubic = cubic(fxy.y);
 
    vec4 c = texCoords.xxyy + vec2(-0.5, 1.5).xyxy;
 
    vec4 s = vec4(xcubic.xz + xcubic.yw, ycubic.xz + ycubic.yw);
    vec4 offset = c + vec4(xcubic.yw, ycubic.yw) / s;
 
    offset *= invTexSize.xxyy;
 
    vec4 sample0 = texture2D(image, offset.xz);
    vec4 sample1 = texture2D(image, offset.yz);
    vec4 sample2 = texture2D(image, offset.xw);
    vec4 sample3 = texture2D(image, offset.yw);
 
    float sx = s.x / (s.x + s.y);
    float sy = s.z / (s.z + s.w);
 
    return mix(mix(sample3, sample2, sx), mix(sample1, sample0, sx), sy);
}

vec4 texture2DBox(sampler2D image, vec2 texCoords, vec2 texSize){
    vec2 invTexSize = 1.0 / texSize;
	vec4 sample = texture2D(image, texCoords - invTexSize) + texture2D(image, texCoords + invTexSize) +
    texture2D(image, texCoords - vec2(-invTexSize.x, invTexSize.y)) + texture2D(image, texCoords + vec2(-invTexSize.x, invTexSize.y));
	return sample * 0.25;
	}