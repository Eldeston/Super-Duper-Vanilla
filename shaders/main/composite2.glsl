#include "/lib/util.glsl"
#include "/lib/structs.glsl"
#include "/lib/settings.glsl"
#include "/lib/globalVar.glsl"

#include "/lib/globalSamplers.glsl"

INOUT vec2 texcoord;

#ifdef VERTEX
    void main() {
        gl_Position = ftransform();
        texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    }
#endif

#ifdef FRAGMENT
    void main() {
        // Original scene color
        vec3 color = texture2D(gcolor, texcoord).rgb;

        // Get lod
        float lod = int(exp2(min(viewWidth, viewHeight))) - 1.0;
        // Get average scene brightenss...
        vec3 colCurrent = texture2D(gcolor, vec2(0.5), lod).rgb;
        vec3 colPrev = texture2D(colortex6, vec2(0.5), lod).rgb;
        // Mix previous and current buffer...
        vec3 finalCol = mix(colCurrent, colPrev, exp2(-1.0 * frameTime));

        // Calculate luminance
        float lumi = maxC(colPrev);
        // Apply exposure
        color /= max(0.25, lumi) * 2.0;
        // Clamp
        color = saturate(color);

    /* DRAWBUFFERS:06 */
        gl_FragData[0] = vec4(color, 1); //gcolor
        gl_FragData[1] = vec4(finalCol, 1); //colortex6
    }
#endif