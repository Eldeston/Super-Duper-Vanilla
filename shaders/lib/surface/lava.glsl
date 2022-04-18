float getLavaNoise(vec2 uv){
    float animateTime = CURRENT_SPEED * newFrameTimeCounter * 0.015625;
    return (1.0 - texture2D(noisetex, uv * 0.5 + animateTime).z) * 0.7 + texture2D(noisetex, (animateTime - uv) * 2.0).z * 0.3;
}