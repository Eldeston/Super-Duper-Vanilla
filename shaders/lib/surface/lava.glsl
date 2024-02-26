float getLavaNoise(in vec2 uv){
    const float currentSpeed = CURRENT_SPEED * 0.015625;
    float animateTime = fragmentFrameTime * currentSpeed;
    return (1.0 - textureLod(noisetex, uv * 0.5 + animateTime, 0).z) * 0.7 + textureLod(noisetex, (animateTime - uv) * 2.0, 0).z * 0.3;
}