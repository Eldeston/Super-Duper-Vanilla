vec3 toneA(vec3 base){
	return toneContrast(toneSaturation(base.rgb, SATURATION), CONTRAST);
}

vec3 whitePreservingLumaBasedReinhardToneMapping(vec3 color){
	float luma = sumOf(color) * 0.33333333;
	float lumaSqrd = luma * luma;
	return color * ((luma + lumaSqrd * 0.125) / (luma + lumaSqrd));
}