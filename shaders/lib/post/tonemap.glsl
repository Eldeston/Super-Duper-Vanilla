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

// Modified reinhard tonemapping
vec3 modifiedReinhardTonemapping(in vec3 color){
	const float oneMinusShoulder = 1.0 - SHOULDER_STRENGTH;

	const float shoulderFactor = oneMinusShoulder * 3.0;
	const float shoulderWhitePointFactor = oneMinusShoulder / (WHITE_POINT * WHITE_POINT);

	float sumCol = sumOf(color);
	return color * ((3.0 + sumCol * shoulderWhitePointFactor) / (shoulderFactor + sumCol));
}