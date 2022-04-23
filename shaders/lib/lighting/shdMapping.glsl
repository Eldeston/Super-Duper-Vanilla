const float sunPathRotation = 30.0; // Light angle [-60.0 -55.0 -50.0 -45.0 -40.0 -35.0 -30.0 -25.0 -20.0 -15.0 -10.0 -5.0 0.0 5.0 10.0 15.0 20.0 25.0 30.0 35.0 40.0 45.0 50.0 55.0 60.0]

#if defined SHD_ENABLE && defined WORLD_LIGHT
	// Enable filtering on shadows
	const bool shadowHardwareFiltering = true;
	const int shadowMapResolution = 1024; // Shadow map resolution. Increase for more resolution at the cost of performance. [512 1024 1536 2048 2560 3072 3584 4096 4608 5120 5632 6144 6656 7168 7680 8192]

	const float shadowDistance = 128.0; // Shadow distance. Increase to stretch the shadow map to farther distances in blocks. It's recommended to match this setting with your render distance and increase your shadow map resolution. [32.0 64.0 96.0 128.0 160.0 192.0 224.0 256.0 288.0 320.0 352.0 384.0 416.0 448.0 480.0 512.0 544.0 576.0 608.0 640.0 672.0 704.0 736.0 768.0 800.0 832.0 864.0 896.0 928.0 960.0 992.0 1024.0]
	const float shadowDistanceRenderMul = 1.0; // Hardcoded to be always on for maximum optimization.

	// Shadow opaque
	uniform sampler2DShadow shadowtex0;

	#ifdef SHD_COL
		// Shadow w/o translucents
		uniform sampler2DShadow shadowtex1;

		// Shadow color
		uniform sampler2D shadowcolor0;
	#endif

	vec3 getShdTex(vec3 shdPos){
		#ifdef SHD_COL
			float shd0 = shadow2D(shadowtex0, shdPos).x;
			float shd1 = shadow2D(shadowtex1, shdPos).x - shd0;

			return texture2D(shadowcolor0, shdPos.xy).rgb * (shd1 - shd1 * shd0) + shd0;
		#else
			return shadow2D(shadowtex0, shdPos).xxx;
		#endif
	}

	vec3 getShdFilter(vec3 shdPos, float dither){
		vec2 randVec = vec2(sin(dither), cos(dither)) / shadowMapResolution;
		return (getShdTex(vec3(shdPos.xy + randVec, shdPos.z)) + getShdTex(vec3(shdPos.xy - randVec, shdPos.z))) * 0.5;
	}
#endif