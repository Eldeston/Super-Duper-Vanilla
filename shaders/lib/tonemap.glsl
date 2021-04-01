vec3 toneA(vec3 base){
	return pow(toneContrast(toneSaturation(base.rgb, SATURATION), CONTRAST), vec3(1.0 / GAMMA));
}