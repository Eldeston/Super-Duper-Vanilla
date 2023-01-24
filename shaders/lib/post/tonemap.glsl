vec3 toneA(in vec3 base){
	return toneContrast(toneSaturation(base, SATURATION), CONTRAST);
}

vec3 whitePreservingLumaBasedReinhardToneMapping(in vec3 color){
	float luma = sumOf(color) * 0.33333333;
	return color * ((1.0 + luma * 0.25) / (1.0 + luma));
}