vec3 toneA(vec3 base){
	return toneContrast(toneSaturation(base.rgb, SATURATION), CONTRAST);
}

vec3 whitePreservingLumaBasedReinhardToneMapping(vec3 color){
	float luma = getLuminance(color);
	float toneMappedLuma = (luma * (1.0 + luma / squared(WHITE_PRESERVATION))) / (1.0 + luma);
	return saturate(pow(color * (toneMappedLuma / luma), vec3(1.0 / GAMMA)));
}