vec3 toneA(vec3 base){
	return toneContrast(toneSaturation(base.rgb, SATURATION), CONTRAST);
}

vec3 whitePreservingLumaBasedReinhardToneMapping(vec3 color){
	float luma = getLuminance(color);
	float lumaSqrd = luma * luma;
	return color * ((luma + lumaSqrd * 0.21763764) / (luma + lumaSqrd));
}