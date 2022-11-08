float getLavaNoise(in vec2 uv){
    float animateTime = CURRENT_SPEED * newFrameTimeCounter * 0.015625;
    return (1.0 - texture2DLod(noisetex, uv * 0.5 + animateTime, 0).z) * 0.7 + texture2DLod(noisetex, (animateTime - uv) * 2.0, 0).z * 0.3;
}