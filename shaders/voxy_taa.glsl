{
#if ANTI_ALIASING == 2
    const vec2 offSetsTAA[8] = vec2[8](
        vec2(0.125, -0.375),
        vec2(-0.125, 0.375),
        vec2(0.625, 0.125),
        vec2(0.375, -0.625),
        vec2(-0.625, 0.625),
        vec2(-0.875, -0.125),
        vec2(0.375, -0.875),
        vec2(0.875, 0.875)
    );
    return offSetsTAA[frameMod % 8] * vec2(pixelWidth, pixelHeight);
#else
    return vec2(0.0);
#endif
}
