float getCellNoise(vec2 st){
    float animateTime = CURRENT_SPEED * newFrameTimeCounter;
    float heightMap = texture2D(noisetex, st + animateTime * 0.025).z;
    return (heightMap + texture2D(noisetex, st - animateTime * 0.05).z) * 0.5;
}