float getCellNoise(vec2 st){
    float animateTime = CURRENT_SPEED * newFrameTimeCounter * 0.05;
    return (texture2D(noisetex, st + animateTime).z + texture2D(noisetex, animateTime - st).z) * 0.5;
}