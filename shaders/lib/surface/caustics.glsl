float getCellNoise(vec2 st){
    float animateTime = CURRENT_SPEED * newFrameTimeCounter * 0.0625;
    return (texture2D(noisetex, st + animateTime * 0.5).z + texture2D(noisetex, animateTime - st).z) * 0.5;
}