#version 120

#include "/lib/frameBuffer.glsl"
#include "/lib/util.glsl"

uniform int isEyeInWater;

IN vec4 texCoord;

void main(){
    vec3 color = getAlbedo(texCoord.st);
    
    #ifdef UNDERWATER_BLUR
        #ifdef FAST_UNDERWATER_BLUR
            if(isEyeInWater == 1) color = blur1(gcolor, texCoord.st, UNDERWATER_BLUR_PIX_SIZE, UNDERWATER_BLUR_SAMPLES / 2, UNDERWATER_BLUR_LOD).rgb;
        #else
            if(isEyeInWater == 1) color = blur2(gcolor, texCoord.st, UNDERWATER_BLUR_PIX_SIZE, UNDERWATER_BLUR_SAMPLES, UNDERWATER_BLUR_LOD).rgb;
        #endif
    #endif

    #ifdef BLOOM
        #ifdef FAST_BLOOM
            vec3 blurBloom = blur1(colortex3, texCoord.st, BLOOM_PIX_SIZE, BLOOM_SAMPLES / 2, BLOOM_LOD).rgb;
        #else
            vec3 blurBloom = blur2(colortex3, texCoord.st, BLOOM_PIX_SIZE, BLOOM_SAMPLES, BLOOM_LOD).rgb;
        #endif
        if(isEyeInWater != 1) color += blurBloom * BLOOM_BRIGHTNESS;
    #endif

	color = toneA(color);

	#ifdef HDR
		color = rgb2hdr(color);
	#endif

    #ifdef VIGNETTE
        // Apply vignette
        color *= pow(max(1.0 - length(texCoord.st - 0.5), 0.0), VIGNETTE_INTENSITY);
    #endif

    gl_FragColor = vec4(color, 1.0);
}