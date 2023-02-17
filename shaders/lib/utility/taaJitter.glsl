// Jitter offset from Chocapic13
const vec2 offSetsTAA[8] = vec2[8](
    vec2(0.125,-0.375),
    vec2(-0.125, 0.375),
    vec2(0.625, 0.125),
    vec2(0.375,-0.625),
    vec2(-0.625, 0.625),
    vec2(-0.875,-0.125),
    vec2(0.375,-0.875),
    vec2(0.875, 0.875)
);

vec2 jitterPos(in float posW){
	return offSetsTAA[frameMod8] * vec2(pixelWidth, pixelHeight) * posW;
}