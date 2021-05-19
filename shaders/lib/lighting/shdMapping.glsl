// Shadow texture
uniform sampler2DShadow shadowtex0;
uniform sampler2DShadow shadowtex1;

// Shadow color
uniform sampler2D shadowcolor0;

// Shadow bias
const float shdBias = 0.025; // Don't go below it otherwise it'll mess up lighting

vec2 offSetShd[3] = vec2[3](
    vec2(0),
    vec2(-1) / shadowMapResolution,
    vec2(1) / shadowMapResolution
);

vec3 getShdFilter(vec4 shdPos, float dither){
	dither *= PI2;
	vec2 randVec = vec2(sin(dither), cos(dither));
	float shd0, shd1 = 0.0;
	vec3 shdCol = vec3(0);
	float lightDiff = max(0.0, shdPos.w);

	for(int i = 1; i < 3; i++){
		vec2 shdOffSet = randVec * offSetShd[i];
		shd0 = min(shadow2D(shadowtex0, vec3(shdPos.xy + shdOffSet, shdPos.z)).x, lightDiff);
		shd1 = min(shadow2D(shadowtex1, vec3(shdPos.xy + shdOffSet, shdPos.z)).x, lightDiff) - shd0;

		#ifdef SHD_COL
			shdCol += texture2D(shadowcolor0, shdPos.xy + shdOffSet).rgb * shd1 * (1.0 - shd0) + shd0;
		#else
			shdCol += shd0;
		#endif
	}

	return shdCol * 0.333;
}

// Shadow function
vec3 getShdMapping(matPBR material, vec4 shdPos, vec3 nLightPos, float dither){
	// Light diffuse
	float lightDot = dot(material.normal_m, nLightPos) * (1.0 - material.ss_m) + material.ss_m;
	vec3 shdCol = vec3(0);

	#ifndef NETHER
		shdPos.xyz = distort(shdPos.xyz, shdPos.w) * 0.5 + 0.5;
		shdPos.z -= shdBias * squared(shdPos.w) / abs(lightDot);

		if(lightDot >= 0.0){
			#ifdef SHADOW_FILTER
				shdCol = getShdFilter(vec4(shdPos.xyz, lightDot), dither);
			#else
				float lightDiff = saturate(lightDot);
				float shd0, shd1 = 0.0;

				shd0 = min(shadow2D(shadowtex0, shdPos.xyz).x, lightDiff);
				shd1 = min(shadow2D(shadowtex1, shdPos.xyz).x, lightDiff) - shd0;
				
				#ifdef SHD_COL
					shdCol = texture2D(shadowcolor0, shdPos.xy).rgb * shd1 * (1.0 - shd0) + shd0;
				#else
					shdCol = shd0;
				#endif
			#endif
		}
	#endif

	return shdCol * (1.0 - newTwilight);
}