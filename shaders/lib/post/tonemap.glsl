vec3 toneA(vec3 base){
	return toneContrast(toneSaturation(base.rgb, SATURATION), CONTRAST);
}

vec3 whitePreservingLumaBasedReinhardToneMapping(vec3 color){
	float luma = sumOf(color) * 0.33333333;
	return color * (1.0 + luma * 0.1) / (1.0 + luma);
	// vec3 colorSqrd = color * color;
	// return colorSqrd / (luma + colorSqrd);
}