vec3 toneA(vec3 base){
	return pow(A_Contrast(A_Saturation(base.rgb, SATURATION), CONTRAST), vec3(1.0 / GAMMA));
}