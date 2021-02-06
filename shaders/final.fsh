#version 120

#include "/lib/settings.glsl"
#include "/lib/globalVar.glsl"
#include "/lib/util.glsl"

#include "/lib/tonemaps/tonemap.glsl"
#include "/lib/frameBuffer.glsl"
#include "/lib/post/blur.glsl"

IN vec4 texCoord;

void main(){
    vec3 color = texture2D(gcolor, texCoord.st).rgb;

    color = toneA(color);

    #ifdef VIGNETTE
        // Apply vignette
        color *= pow(max(1.0 - length(texCoord.st - 0.5), 0.0), VIGNETTE_INTENSITY);
    #endif

    gl_FragColor = vec4(color, 1.0);
}