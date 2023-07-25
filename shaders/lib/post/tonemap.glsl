// Luminance function
float getLuminance(in vec3 col){
	return dot(col, vec3(0.2126, 0.7152, 0.0722));
}

// Saturation function
vec3 saturation(in vec3 col, in float a){
	float luma = getLuminance(col);
	return (col - luma) * a + luma;
}

// Contrast function
vec3 contrast(in vec3 col, in float a){
	return (col - 0.5) * a + 0.5;
}

vec3 whitePreservingLumaBasedReinhardToneMapping(in vec3 color){
	float sumCol = sumOf(color);
	return color * ((3.0 + sumCol * 0.25) / (3.0 + sumCol));
}