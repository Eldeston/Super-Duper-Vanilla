// Filter by iq
vec4 tex2DBicubic(sampler2D image, vec2 st, vec2 texRes){
    vec2 uv = st * texRes + 0.5;
    vec2 iuv = floor(uv); vec2 fuv = fract(uv);
    uv = iuv + fuv * fuv * fuv * (fuv * (fuv * 6.0 - 15.0) + 10.0);
    uv = (uv - 0.5) / texRes;
    return texture2D(image, uv);
}

vec4 tex2DBilinear(sampler2D image, vec2 st, vec2 texRes){
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

// Noise texture
vec4 getRandTex(vec2 st, int tile){
	return texture2D(noisetex, st * tile);
}

vec3 getRand3(vec2 st, int tile){
    st *= tile;
    float x = texture2D(noisetex, st).x;
    float y = texture2D(noisetex, vec2(-st.x, st.y)).x;
    float z = texture2D(noisetex, -st).x;
    if(NOISE_SPEED == 0) return fract(vec3(x, y, z) * 4.0);
    return fract(vec3(x, y, z) * 4.0 + frameTimeCounter * NOISE_SPEED);
}

float getCellNoise(vec2 st){
    float d0 = tex2DBilinear(noisetex, st + frameTimeCounter * 0.0125, vec2(256)).z;
    float d1 = tex2DBilinear(noisetex, st * 4.0 - frameTimeCounter * 0.05, vec2(256)).z;
    #ifdef INVERSE
        return 1.0 - d0 * 0.875 + d1 * 0.125;
    #else
        return d0 * 0.875 + d1 * 0.125;
    #endif
}

// Convert height map of water to a normal map
vec4 H2NWater(vec2 st){
    float waterPixel = WATER_BLUR_SIZE / noiseTextureResolution;
	vec2 waterUv = st / WATER_TILE_SIZE;

	float d = getCellNoise(waterUv);
	float dx = (d - getCellNoise(waterUv + vec2(waterPixel, 0))) / waterPixel;
	float dy = (d - getCellNoise(waterUv + vec2(0, waterPixel))) / waterPixel;

    #ifdef INVERSE
        d = 1.0 - d;
    #endif
    
    return vec4(normalize(vec3(dx, dy, WATER_DEPTH_SIZE)), d);
}