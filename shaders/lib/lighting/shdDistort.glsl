const int shadowMapResolution = 1024; // Shadow map resolution. Increase for more resolution at the cost of performance. [512 1024 1536 2048 2560 3072 3584 4096 4608 5120 5632 6144 6656 7168 7680 8192]

const float shadowDistance = 128.0; // Shadow distance. Increase to stretch the shadow map to farther distances in blocks. It's recommended to match this setting with your render distance and increase your shadow map resolution. [32.0 64.0 96.0 128.0 160.0 192.0 224.0 256.0 288.0 320.0 352.0 384.0 416.0 448.0 480.0 512.0 544.0 576.0 608.0 640.0 672.0 704.0 736.0 768.0 800.0 832.0 864.0 896.0 928.0 960.0 992.0 1024.0]

float getDistortFactor(vec2 pos){
	return length(pos) + 0.1;
}

vec3 distort(vec3 pos, float factor){
	return vec3(pos.xy / factor, pos.z * 0.2);
}

vec3 distort(vec3 pos){
	return distort(pos, getDistortFactor(pos.xy));
}