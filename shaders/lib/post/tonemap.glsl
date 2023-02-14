vec3 toneA(in vec3 base){
	return toneContrast(toneSaturation(base, SATURATION), CONTRAST);
}

vec3 whitePreservingLumaBasedReinhardToneMapping(in vec3 color){
	float sumCol = sumOf(color);
	return color * ((3.0 + sumCol * 0.25) / (3.0 + sumCol));
}