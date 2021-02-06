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
	vec2 uv = texcoord;
    vec2 resolution = vec2(viewWidth, viewHeight);

    #ifdef UNDERWATER_DISTORTION
        if(isEyeInWater == 1)
            uv.x += sin((uv.x + uv.y) * DISTORT_FREQUENCY + frameTimeCounter * DISTORT_SPEED) * DISTORT_AMOUNT;
    #endif

    vec3 color = texture2D(gcolor, uv).rgb;

    #ifdef UNDERWATER_BLUR
        if(isEyeInWater == 1)
            #ifdef FAST_UNDERWATER_BLUR
                color = blur1x(gcolor, uv, resolution, UNDERWATER_BLUR_SIZE);
            #else
                color = blur2(gcolor, uv, resolution, UNDERWATER_BLUR_SAMPLES / 2, UNDERWATER_BLUR_SIZE);
            #endif
    #endif

    vec3 bloomCol = vec3(0.0);

    #ifdef BLOOM
        if(isEyeInWater != 1)
            #ifdef FAST_BLOOM
                bloomCol += blur1x(colortex3, uv, resolution, BLOOM_SIZE);
            #else
                bloomCol += blur2(colortex3, uv, resolution, BLOOM_SAMPLES / 2, BLOOM_SIZE);
            #endif
        bloomCol = saturate(bloomCol);
    #endif

/* DRAWBUFFERS:03 */
	gl_FragData[0] = vec4(color, 1.0); //gcolor
    gl_FragData[1] = vec4(bloomCol, 1.0); //colortex3
}