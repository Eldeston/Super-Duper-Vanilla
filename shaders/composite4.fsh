#version 120

/* Blur and bloom goes here */

#include "/lib/settings.glsl"
#include "/lib/globalVar.glsl"
#include "/lib/util.glsl"

#include "/lib/frameBuffer.glsl"

#include "/lib/lighting/shdDistort.glsl"
#include "/lib/transform/conversion.glsl"
#include "/lib/tonemaps/tonemap.glsl"
#include "/lib/post/blur.glsl"

// Must come in last
#include "/lib/transform/varAssembler.glsl"

IN vec2 texcoord;

void main(){
    vec2 resolution = vec2(viewWidth, viewHeight);
    vec3 color = texture2D(gcolor, texcoord).rgb;

    #ifdef UNDERWATER_BLUR
        if(isEyeInWater == 1)
            #ifdef FAST_UNDERWATER_BLUR
                color = blur1y(gcolor, texcoord, resolution, UNDERWATER_BLUR_SIZE);
            #else
                color = blur2(gcolor, texcoord, resolution, UNDERWATER_BLUR_SAMPLES / 2, UNDERWATER_BLUR_SIZE);
            #endif
    #endif

    #ifdef BLOOM
        if(isEyeInWater != 1)
            #ifdef FAST_BLOOM
                color += blur1y(colortex3, texcoord, resolution, BLOOM_SIZE) * BLOOM_BRIGHTNESS;
            #else
                color += blur2(colortex3, texcoord, resolution, BLOOM_SAMPLES / 2, BLOOM_SIZE) * BLOOM_BRIGHTNESS;
            #endif
        color = saturate(color);
    #endif

/* DRAWBUFFERS:0 */
	gl_FragData[0] = vec4(color, 1.0); //gcolor
}