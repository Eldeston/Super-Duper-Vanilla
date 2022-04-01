float getLavaNoiseBilinear(vec2 uv){
    float pixSize = 1.0 / noiseTextureResolution;

    float downLeft = texture2D(noisetex, uv).x;
    float downRight = texture2D(noisetex, uv + vec2(pixSize, 0)).x;

    float upRight = texture2D(noisetex, uv + vec2(0, pixSize)).x;
    float upLeft = texture2D(noisetex, uv + pixSize).x;

    float a = fract(uv.x * noiseTextureResolution);

    float horizontal0 = mix(downLeft, downRight, a);
    float horizontal1 = mix(upRight, upLeft, a);
    return mix(horizontal0, horizontal1, fract(uv.y * noiseTextureResolution));
}

float getLavaNoise(vec2 uv){
    float animateTime = CURRENT_SPEED * newFrameTimeCounter * 0.03125;
    float noiseMap = getLavaNoiseBilinear((uv - animateTime) * 0.015625);
    return 1.0 - (noiseMap + texture2D(noisetex, uv + animateTime).z) * 0.5;
}