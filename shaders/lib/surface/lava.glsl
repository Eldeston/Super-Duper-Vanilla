float getCellNoise2(vec2 st){
    float animateTime = CURRENT_SPEED * newFrameTimeCounter * 0.032;
    float noiseMap = texPix2DBilinear(noisetex, (st - animateTime) * 0.015625, vec2(noiseTextureResolution)).y;
    return 1.0 - (noiseMap + texture2D(noisetex, st + animateTime).z) * 0.5;
}