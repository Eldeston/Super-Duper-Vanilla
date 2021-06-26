vec3 toneA(vec3 base){
	return toneContrast(toneSaturation(base.rgb, SATURATION), CONTRAST);
}