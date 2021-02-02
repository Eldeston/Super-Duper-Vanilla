#version 120

#include "/lib/settings.glsl"
#include "/lib/globalVar.glsl"
#include "/lib/util.glsl"

#include "/lib/tonemaps/tonemap.glsl"
#include "/lib/frameBuffer.glsl"
#include "/lib/post/blur.glsl"

IN vec4 texCoord;

void main(){
    vec2 uv = texCoord.xy;
    vec2 resolution = vec2(viewWidth, viewHeight);

    #ifdef UNDERWATER_DISTORTION
        if(isEyeInWater == 1) uv.x += sin((uv.x + uv.y) * DISTORT_FREQUENCY + frameTimeCounter * DISTORT_SPEED) * DISTORT_AMOUNT;
    #endif

    vec3 color = texture2D(gcolor, uv).rgb;

    #ifdef UNDERWATER_BLUR
        if(isEyeInWater == 1)
            #ifdef FAST_UNDERWATER_BLUR
                color = blur1(gcolor, uv, resolution, UNDERWATER_BLUR_SAMPLES, UNDERWATER_BLUR_SIZE);
            #else
                color = blur2(gcolor, uv, resolution, UNDERWATER_BLUR_SAMPLES, UNDERWATER_BLUR_SIZE);
            #endif
    #endif

    #ifdef BLOOM
        if(isEyeInWater != 1)
            #ifdef FAST_BLOOM
                color += blur1(colortex3, texCoord.st, resolution, BLOOM_SAMPLES / 2, BLOOM_SIZE) * BLOOM_BRIGHTNESS;
            #else
                color += blur2(colortex3, texCoord.st, resolution, BLOOM_SAMPLES, BLOOM_SIZE) * BLOOM_BRIGHTNESS;
            #endif
        color = saturate(color);
    #endif

    color = toneA(color);

    #ifdef VIGNETTE
        // Apply vignette
        color *= pow(max(1.0 - length(texCoord.st - 0.5), 0.0), VIGNETTE_INTENSITY);
    #endif

    gl_FragColor = vec4(color, 1.0);
}